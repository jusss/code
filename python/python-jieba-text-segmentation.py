import jieba
import jieba.analyse
import jieba.posseg as pseg

stop_words=["的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都", "一", "一个", "上", "也",
            "很", "到", "you", "a"]

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

def text_segment(text, topK=3):
    keywords = jieba.analyse.extract_tags(text, topK=topK)
    keywords = filter_tags(list(set(keywords)), stop_words)
    return keywords

if __name__ == '__main__':
    text = "北京今天的天气"
    r = text_segment(text, topK=3)
    print(r)


    query = "Do you want a drink"
    target = [{"question":"do you like an apple"}, {"question":"want a drink"}]


    keywords = text_segment(query)
    result = []
    for rec in target:
        for key in keywords:
            if key in rec["question"]:
                  result.append(rec)
                  break
    print(result)
