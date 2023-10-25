from datetime import datetime, timedelta

def get_user_input(message):
    return input(message)

def is_leap_year(year):
    if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
        return True
    return False

def calculate_date_difference(start_date, end_date):
    return abs((end_date - start_date).days)

while True:
    print("날짜 계산기")
    print("1. 현재 날짜에서 이동")
    print("2. 날짜 입력 및 날짜 차이 계산")
    print("3. 날짜 입력 및 이동")
    print("4. 날짜 입력 및 날짜 차이 계산")
    
    choice = get_user_input("기능을 선택하세요 (1, 2, 3, 또는 4): ")
    
    if choice == "1":
        try:
            days_to_move = int(get_user_input("양수로 미래로, 음수로 과거로 이동할 날 수를 입력하세요: "))
            current_date = datetime.now()
            future_date = current_date + timedelta(days=days_to_move)
            print(f"이동한 날짜: {future_date.strftime('%Y-%m-%d')}")
        except ValueError:
            print("올바르지 않은 날짜 형식입니다.")
    elif choice == "2":
        try:
            date_input = get_user_input("날짜를 입력하세요 (YYYY-MM-DD): ")
            input_date = datetime.strptime(date_input, "%Y-%m-%d")
            current_date = datetime.now()
            days_to_move = (current_date - input_date).days
            print(f"현재 날짜와의 날짜 차이: {days_to_move} 일")
        except ValueError:
            print("올바르지 않은 날짜 형식입니다.")
    elif choice == "3":
        try:
            date_input = get_user_input("기준 날짜를 입력하세요 (YYYY-MM-DD): ")
            input_date = datetime.strptime(date_input, "%Y-%m-%d")
            days_to_move = int(get_user_input("양수로 미래로, 음수로 과거로 이동할 날 수를 입력하세요: "))
            future_date = input_date + timedelta(days=days_to_move)
            print(f"이동한 날짜: {future_date.strftime('%Y-%m-%d')}")
        except ValueError:
            print("올바르지 않은 날짜 형식입니다.")
    elif choice == "4":
        try:
            date_input1 = get_user_input("첫 번째 날짜를 입력하세요 (YYYY-MM-DD): ")
            date_input2 = get_user_input("두 번째 날짜를 입력하세요 (YYYY-MM-DD): ")
            input_date1 = datetime.strptime(date_input1, "%Y-%m-%d")
            input_date2 = datetime.strptime(date_input2, "%Y-%m-%d")
            date_difference = calculate_date_difference(input_date1, input_date2)
            print(f"날짜 차이: {date_difference} 일")
        except ValueError:
            print("올바르지 않은 날짜 형식입니다.")
    else:
        print("올바른 기능을 선택하세요.")
    
    repeat = get_user_input("다시 실행하시겠습니까? (y/n): ")
    if repeat.lower() != "y":
        break
