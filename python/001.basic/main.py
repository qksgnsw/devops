# main.py
from user_utils import User, get_user_input

def main():
    users = []

    while True:
        user = get_user_input()
        users.append(user)

        more_users = input("더 사용자 정보를 입력하시겠습니까? (Y/N): ")
        if more_users.lower() != 'y':
            break

    for user in users:
        print("\n사용자 정보:")
        print("이름:", user.name)
        print("나이:", user.age)
        print("좋아하는 프로그래밍 언어:", user.favorite_language)
        print("좋아하는 과일:", user.favorite_fruits)

if __name__ == "__main__":
    main()
