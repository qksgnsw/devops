import random

# 게임의 상태를 나타내는 클래스 정의
class NumberGuessingGame:
    def __init__(self):
        self.secret_number = random.randint(1, 100)
        self.attempts = 0

    def play(self):
        while True:
            guess = int(input("1부터 100 사이의 숫자를 추측해보세요: "))
            self.attempts += 1

            if guess < self.secret_number:
                print("더 큰 숫자를 선택하세요.")
            elif guess > self.secret_number:
                print("더 작은 숫자를 선택하세요.")
            else:
                print(f"축하합니다! {self.secret_number}를 {self.attempts}번만에 맞추셨습니다.")
                break

# AI를 구현하는 클래스 정의
class SimpleAI:
    def guess(self):
        return random.randint(1, 100)

def main():
    print("숫자 맞추기 게임을 시작합니다.")
    choice = input("AI와 대결하려면 '1', 사람과 대결하려면 '2'를 입력하세요: ")

    if choice == '1':
        game = NumberGuessingGame()
        game.play()
    elif choice == '2':
        player_attempts = 0
        secret_number = random.randint(1, 100)

        while True:
            guess = int(input("AI가 생각한 숫자를 맞춰보세요: "))
            player_attempts += 1

            if guess < secret_number:
                print("더 큰 숫자를 선택하세요.")
            elif guess > secret_number:
                print("더 작은 숫자를 선택하세요.")
            else:
                print(f"축하합니다! {secret_number}를 {player_attempts}번만에 맞추셨습니다.")
                break

if __name__ == "__main__":
    main()
