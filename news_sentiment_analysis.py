#!/usr/bin/env python3
"""
Advanced Sentiment Analysis for News Articles
Uses VADER, TextBlob, and DistilBERT
"""

from google.cloud import bigquery
import pandas as pd
import numpy as np

# Sentiment analysis libraries
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from textblob import TextBlob
from transformers import pipeline
import matplotlib.pyplot as plt
import seaborn as sns

# Initialize
import os

# Clear invalid GOOGLE_APPLICATION_CREDENTIALS if file doesn't exist
if os.environ.get('GOOGLE_APPLICATION_CREDENTIALS'):
    cred_path = os.environ.get('GOOGLE_APPLICATION_CREDENTIALS')
    if not os.path.exists(cred_path):
        print(f"Warning: GOOGLE_APPLICATION_CREDENTIALS points to non-existent file: {cred_path}")
        os.environ.pop('GOOGLE_APPLICATION_CREDENTIALS', None)
        print("Unset GOOGLE_APPLICATION_CREDENTIALS. Using gcloud default credentials.")

try:
    client = bigquery.Client(project='news-express-prod')
except Exception as e:
    print(f"Error initializing BigQuery client: {e}")
    print("\nPlease run: gcloud auth application-default login")
    print("Or set GOOGLE_APPLICATION_CREDENTIALS to a valid service account key file.")
    raise

def fetch_news_data():
    """Fetch news data from BigQuery"""
    query = """
    SELECT 
        uuid,
        title,
        description,
        source.name as source,
        CONCAT(COALESCE(title, ''), '. ', COALESCE(description, '')) as text
    FROM `news-express-prod.news_stream.news_table`
    WHERE title IS NOT NULL
    LIMIT 100
    """
    return client.query(query).to_dataframe()

def vader_sentiment(text):
    """VADER: Rule-based sentiment (great for social media/news)"""
    analyzer = SentimentIntensityAnalyzer()
    scores = analyzer.polarity_scores(text)
    return {
        'vader_score': scores['compound'],
        'vader_pos': scores['pos'],
        'vader_neu': scores['neu'],
        'vader_neg': scores['neg'],
        'vader_label': 'POSITIVE' if scores['compound'] > 0.05 
                       else 'NEGATIVE' if scores['compound'] < -0.05 
                       else 'NEUTRAL'
    }

def textblob_sentiment(text):
    """TextBlob: Simple lexicon-based approach"""
    blob = TextBlob(text)
    polarity = blob.sentiment.polarity
    subjectivity = blob.sentiment.subjectivity
    return {
        'textblob_score': polarity,
        'textblob_subjectivity': subjectivity,
        'textblob_label': 'POSITIVE' if polarity > 0.1 
                          else 'NEGATIVE' if polarity < -0.1 
                          else 'NEUTRAL'
    }

def distilbert_sentiment(texts, batch_size=8):
    """DistilBERT: Transformer-based (most accurate)"""
    print("Loading DistilBERT model (first time may take a while)...")
    sentiment_pipeline = pipeline(
        "sentiment-analysis",
        model="distilbert-base-uncased-finetuned-sst-2-english",
        device=-1  # Use CPU; change to 0 for GPU
    )
    
    results = []
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        # Truncate to 512 tokens (BERT limit)
        batch = [text[:512] for text in batch]
        batch_results = sentiment_pipeline(batch)
        results.extend(batch_results)
    
    return [{
        'distilbert_label': r['label'],
        'distilbert_score': r['score'] if r['label'] == 'POSITIVE' 
                           else -r['score']
    } for r in results]

def analyze_all_methods(df):
    """Apply all 3 sentiment analysis methods"""
    print("\n=== Running Multi-Model Sentiment Analysis ===\n")
    
    # VADER (fast, rule-based)
    print("1. Applying VADER...")
    vader_results = df['text'].apply(vader_sentiment)
    vader_df = pd.DataFrame(vader_results.tolist())
    
    # TextBlob (fast, lexicon-based)
    print("2. Applying TextBlob...")
    textblob_results = df['text'].apply(textblob_sentiment)
    textblob_df = pd.DataFrame(textblob_results.tolist())
    
    # DistilBERT (slower, most accurate)
    print("3. Applying DistilBERT (this may take a minute)...")
    distilbert_results = distilbert_sentiment(df['text'].tolist())
    distilbert_df = pd.DataFrame(distilbert_results)
    
    # Combine all results
    result_df = pd.concat([df, vader_df, textblob_df, distilbert_df], axis=1)
    
    return result_df

def create_ensemble_sentiment(df):
    """Ensemble: Combine all 3 models for best accuracy"""
    # Normalize scores to -1 to 1 range
    df['vader_norm'] = df['vader_score']
    df['textblob_norm'] = df['textblob_score']
    df['distilbert_norm'] = df['distilbert_score']
    
    # Weighted average (DistilBERT gets more weight as it's most accurate)
    df['ensemble_score'] = (
        0.25 * df['vader_norm'] + 
        0.25 * df['textblob_norm'] + 
        0.50 * df['distilbert_norm']
    )
    
    df['ensemble_label'] = df['ensemble_score'].apply(
        lambda x: 'POSITIVE' if x > 0.1 else 'NEGATIVE' if x < -0.1 else 'NEUTRAL'
    )
    
    return df

def analyze_by_source(df):
    """Analyze sentiment trends by news source"""
    print("\n=== Sentiment by News Source ===\n")
    
    source_sentiment = df.groupby('source').agg({
        'ensemble_score': 'mean',
        'vader_score': 'mean',
        'textblob_score': 'mean',
        'distilbert_score': 'mean',
        'uuid': 'count'
    }).round(3)
    
    source_sentiment.columns = ['ensemble', 'vader', 'textblob', 'distilbert', 'count']
    source_sentiment = source_sentiment[source_sentiment['count'] >= 5]
    source_sentiment = source_sentiment.sort_values('ensemble', ascending=False)
    
    print(source_sentiment)
    
    # Visualize
    plt.figure(figsize=(12, 6))
    source_sentiment['ensemble'].plot(kind='barh', color='steelblue')
    plt.xlabel('Average Sentiment Score')
    plt.title('News Sentiment by Source (Ensemble Model)')
    plt.axvline(x=0, color='red', linestyle='--', alpha=0.5)
    plt.tight_layout()
    plt.savefig('sentiment_by_source.png', dpi=300)
    print("\n✓ Saved: sentiment_by_source.png")

def visualize_sentiment_distribution(df):
    """Create sentiment distribution visualizations"""
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # 1. Sentiment label distribution
    label_counts = df['ensemble_label'].value_counts()
    axes[0, 0].pie(label_counts.values, labels=label_counts.index, autopct='%1.1f%%',
                    colors=['#90EE90', '#FFB6C1', '#87CEEB'])
    axes[0, 0].set_title('Overall Sentiment Distribution')
    
    # 2. Score distribution histogram
    axes[0, 1].hist([df[df['ensemble_label']=='POSITIVE']['ensemble_score'],
                     df[df['ensemble_label']=='NEUTRAL']['ensemble_score'],
                     df[df['ensemble_label']=='NEGATIVE']['ensemble_score']],
                    label=['Positive', 'Neutral', 'Negative'],
                    bins=20, alpha=0.7, color=['green', 'gray', 'red'])
    axes[0, 1].set_xlabel('Sentiment Score')
    axes[0, 1].set_ylabel('Count')
    axes[0, 1].set_title('Sentiment Score Distribution')
    axes[0, 1].legend()
    axes[0, 1].axvline(x=0, color='black', linestyle='--', alpha=0.5)
    
    # 3. Model comparison
    model_comparison = pd.DataFrame({
        'VADER': df['vader_label'].value_counts(),
        'TextBlob': df['textblob_label'].value_counts(),
        'DistilBERT': df['distilbert_label'].value_counts(),
        'Ensemble': df['ensemble_label'].value_counts()
    }).fillna(0)
    model_comparison.T.plot(kind='bar', ax=axes[1, 0], stacked=False)
    axes[1, 0].set_title('Model Comparison')
    axes[1, 0].set_ylabel('Count')
    axes[1, 0].legend(title='Sentiment')
    axes[1, 0].tick_params(axis='x', rotation=0)
    
    # 4. Correlation between models
    correlation = df[['vader_score', 'textblob_score', 'distilbert_score', 'ensemble_score']].corr()
    sns.heatmap(correlation, annot=True, cmap='coolwarm', center=0, ax=axes[1, 1])
    axes[1, 1].set_title('Model Score Correlation')
    
    plt.tight_layout()
    plt.savefig('sentiment_analysis_dashboard.png', dpi=300)
    print("✓ Saved: sentiment_analysis_dashboard.png")

def upload_to_bigquery(df):
    """Upload results back to BigQuery"""
    output_cols = ['uuid', 'title', 'source',
                   'vader_score', 'vader_label',
                   'textblob_score', 'textblob_label',
                   'distilbert_score', 'distilbert_label',
                   'ensemble_score', 'ensemble_label']
    
    output_df = df[output_cols]
    
    table_id = "news-express-prod.news_stream.news_sentiment_advanced"
    
    job_config = bigquery.LoadJobConfig(
        write_disposition="WRITE_TRUNCATE",
    )
    
    job = client.load_table_from_dataframe(
        output_df, table_id, job_config=job_config
    )
    job.result()
    
    print(f"\n✓ Uploaded {len(output_df)} rows to {table_id}")

def show_examples(df):
    """Display example articles with their sentiment"""
    print("\n=== Example Articles ===\n")
    
    for sentiment in ['POSITIVE', 'NEGATIVE', 'NEUTRAL']:
        print(f"\n--- {sentiment} Examples ---")
        examples = df[df['ensemble_label'] == sentiment].head(2)
        for idx, row in examples.iterrows():
            print(f"\nTitle: {row['title'][:100]}...")
            print(f"Source: {row['source']}")
            print(f"Ensemble Score: {row['ensemble_score']:.3f}")
            print(f"VADER: {row['vader_score']:.3f}, TextBlob: {row['textblob_score']:.3f}, DistilBERT: {row['distilbert_score']:.3f}")

def main():
    """Main execution"""
    print("=" * 70)
    print("NEWS SENTIMENT ANALYSIS - Multi-Model Approach")
    print("=" * 70)
    
    # Fetch data
    print("\n1. Fetching news data from BigQuery...")
    df = fetch_news_data()
    print(f"✓ Loaded {len(df)} articles")
    
    # Analyze with all methods
    print("\n2. Running sentiment analysis with 3 models...")
    df = analyze_all_methods(df)
    
    # Create ensemble
    print("\n3. Creating ensemble predictions...")
    df = create_ensemble_sentiment(df)
    
    # Show distribution
    print("\n4. Sentiment Distribution:")
    print(df['ensemble_label'].value_counts())
    print(f"\nAverage sentiment score: {df['ensemble_score'].mean():.3f}")
    
    # Show examples
    show_examples(df)
    
    # Analyze by source
    if len(df['source'].unique()) > 1:
        analyze_by_source(df)
    
    # Visualize
    print("\n5. Creating visualizations...")
    visualize_sentiment_distribution(df)
    
    # Upload to BigQuery
    print("\n6. Uploading results to BigQuery...")
    upload_to_bigquery(df)
    
    print("\n" + "=" * 70)
    print("✓ Analysis Complete!")
    print("=" * 70)
    print("\nGenerated files:")
    print("  - sentiment_by_source.png")
    print("  - sentiment_analysis_dashboard.png")
    print("\nBigQuery table: news-express-prod.news_stream.news_sentiment_advanced")

if __name__ == "__main__":
    main()
