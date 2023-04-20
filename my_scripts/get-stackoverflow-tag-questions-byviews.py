import requests

tag = 'python'  # replace with your desired tag
url = f'https://api.stackexchange.com/2.3/questions?order=desc&sort=views&tagged={tag}&site=stackoverflow'
response = requests.get(url)
data = response.json()

for question in data['items']:
    print(question['title'], question['view_count'], question['link'])
