# General NLP steps

## 1. Explore the dataset

Look through the data set in order to see how it is formatted , the labels and contents. Can do so using for loop for first few data points.

```python

messages.head()

for mess_no, message in enumerate(messages[:10]):
    print(mess_no,message)
    print('\n')

```

## 2. Labelling

In the case of the spam/ham messages , the label of whether or not it is spam / ham is at the front of the message , seperated by a tab.

```text

0 ham	Go until jurong point, crazy.. Available only in bugis n great world la e buffet... Cine there got amore wat...

```

We would need to put the label in a different column of the pd data frame.

```python

messages = pd.read_csv('smsspamcollection/SMSSpamCollection',sep='\t',names=['label','message'])

```

Another useful attribute that might contribute could be length of message. To add that we add
the end result would be a neatly seperated table with the label as different rows.

```python

messages['length'] = messages['message'].apply(len)

```

|     | label | message                                                                                                                                                     | length |
| --: | :---- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- | -----: |
|   0 | ham   | Go until jurong point, crazy.. Available only in bugis n great world la e buffet... Cine there got amore wat...                                             |    111 |
|   1 | ham   | Ok lar... Joking wif u oni...                                                                                                                               |     29 |
|   2 | spam  | Free entry in 2 a wkly comp to win FA Cup final tkts 21st May 2005. Text FA to 87121 to receive entry question(std txt rate)T&C's apply 08452810075over18's |    155 |
|   3 | ham   | U dun say so early hor... U c already then say...                                                                                                           |     49 |
|   4 | ham   | Nah I don't think he goes to usf, he lives around here though                                                                                               |     61 |

## Import relevant libraries

```python
import string

mess = 'Sample message! Notice: it has punctuation.'

# Check characters to see if they are in punctuation
nopunc = [char for char in mess if char not in string.punctuation]

# Join the characters again to form the string.
nopunc = ''.join(nopunc) ## The join() method takes all items in an iterable and joins them into one string. the space infront of the join is what seperates the diff words.
```

### Stopwords

stopwords are very common words that they do not help distinguish one source of text from the other.

```python
from nltk.corpus import stopwords
stopwords.words('english')[0:10] # Show some stop words

```

First, we got to split the text up to individual words again. Next, we repeat the same function as nopunc to remove stopwords.

```python
clean_mess = [word for word in nopunc.split() if word.lower() not in stopwords.words('english')] ## put in a list all words that are not in stopwords english.
```

### Function for text pre-processing

```python
def text_process(mess):
    """
    Takes in a string of text, then performs the following:
    1. Remove all punctuation
    2. Remove all stopwords
    3. Returns a list of the cleaned text
    """
    # Check characters to see if they are in punctuation
    nopunc = [char for char in mess if char not in string.punctuation]

    # Join the characters again to form the string.
    nopunc = ''.join(nopunc)

    # Now just remove any stopwords
    return [word for word in nopunc.split() if word.lower() not in stopwords.words('english')]
```

### Tokenization

Apply the function ( text_process ) to the messages in the message row :

```python
messages['message'].head(5).apply(text_process)
```
