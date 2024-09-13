import jieba
import jieba.analyse
import jieba.posseg as pseg

# Sample text
text = "how to filter words in jieba, do you know"

# Extract tags using TF-IDF
tags = jieba.analyse.extract_tags(text, topK=10, withWeight=False)

# Define a list of stop words
stop_words = set(['how', 'to', 'is', 'do', 'you'])

# Function to filter tags
def filter_tags(tags, stop_words):
    filtered_tags = []
    for tag in tags:
        # Skip stop words
        if tag in stop_words:
            continue
        
        # Get part of speech
        word_pos = pseg.lcut(tag)
        if word_pos:
            word, flag = word_pos[0]
            # Example: Filter out certain parts of speech (e.g., adverbs)
            if flag in ['d']:
                continue
        
        filtered_tags.append(tag)
    return filtered_tags

# Apply filtering
filtered_tags = filter_tags(tags, stop_words)

print("Original Tags:", tags)
print("Filtered Tags:", filtered_tags)
