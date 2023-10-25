from sklearn import datasets
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.metrics import accuracy_score
from tqdm import tqdm  # tqdm 라이브러리 임포트

# 붓꽃 데이터셋 불러오기
iris = datasets.load_iris()
X = iris.data
y = iris.target

# 데이터 분할: 학습 데이터와 테스트 데이터
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.3, random_state=42)

# 의사결정 트리 분류 모델 생성
clf = DecisionTreeClassifier()

# 모델 학습
clf.fit(X_train, y_train)

# 예측
y_pred = clf.predict(X_test)

# 정확도 평가
accuracy = accuracy_score(y_test, y_pred)

# tqdm을 사용하여 진행 상태 출력
for i in tqdm(range(100)):
    pass

print(f"모델 정확도: {accuracy * 100:.2f}%")
