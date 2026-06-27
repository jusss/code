import tiktoken

def count_chat_tokens(messages, model="gpt-4o"):
    """
    Count tokens for chat completion messages.
    
    Args:
        messages (list): List of message dicts with 'role' and 'content' keys
        model (str): The model name (default: gpt-4o)
    
    Returns:
        int: Total token count
    """
    try:
        encoding = tiktoken.encoding_for_model(model)
    except KeyError:
        encoding = tiktoken.get_encoding("cl100k_base")
    
    # Token count for each message includes role and content
    # Based on OpenAI's counting methodology
    tokens_per_message = 3  # +1 for role, +1 for content, +1 for message end
    tokens_per_name = 1     # if name is provided
    
    total_tokens = 0
    
    for message in messages:
        # Count tokens for role
        total_tokens += tokens_per_message
        total_tokens += len(encoding.encode(message["role"]))
        
        # Count tokens for content
        total_tokens += len(encoding.encode(message.get("content","")))
        
        # Count tokens for name if present
        if "name" in message:
            total_tokens += tokens_per_name
            total_tokens += len(encoding.encode(message["name"]))
    
    # Add 3 tokens for the final reply
    total_tokens += 3
    
    return total_tokens

# Example usage:
if __name__ == "__main__":
    messages = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Hello, how are you?"},
        {"role": "assistant", "content": "I'm doing well, thank you! How can I help you today?"}
    ]
    
    token_count = count_chat_tokens(messages)
    print(f"Chat message token count: {token_count}")
