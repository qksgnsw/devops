# user_utils.py

class User:
    def __init__(self, name, age, favorite_language, favorite_fruits):
        self.name = name
        self.age = age
        self.favorite_language = favorite_language
        self.favorite_fruits = favorite_fruits

def is_valid_korean_name(name):
    return all('가' <= char <= '힣' for char in name)

def get_user_input():
    while True:
        name = input("이름을 입력하세요: ")
        if is_valid_korean_name(name):
            break
        else:
            print("올바른 한글 이름이 아닙니다. 다시 입력해주세요.")

    while True:
        try:
            age = int(input("나이를 입력하세요: "))
            break
        except ValueError:
            print("올바른 나이를 입력해주세요.")

    favorite_language = input("좋아하는 프로그래밍 언어를 입력하세요: ")

    favorite_fruits = input("좋아하는 과일을 입력하세요: ")

    return User(name, age, favorite_language, favorite_fruits)
