import tensorflow as tf
from tensorflow import keras
from tqdm import tqdm  # tqdm 라이브러리 임포트

# MNIST 데이터셋 로드
mnist = keras.datasets.mnist
(train_images, train_labels), (test_images, test_labels) = mnist.load_data()

# 이미지 픽셀 값을 0-1 사이로 정규화
train_images, test_images = train_images / 255.0, test_images / 255.0

# 간단한 신경망 모델 생성
model = keras.models.Sequential([
    keras.layers.Flatten(input_shape=(28, 28)),
    keras.layers.Dense(128, activation='relu'),
    keras.layers.Dropout(0.2),
    keras.layers.Dense(10, activation='softmax')
])

# 모델 컴파일
model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

# 모델 학습
model.fit(train_images, train_labels, epochs=5)

# tqdm을 사용하여 진행 상태 출력
for i in tqdm(range(1000)):
    pass

# 모델 평가
test_loss, test_acc = model.evaluate(test_images, test_labels)
print(f"테스트 정확도: {test_acc * 100:.2f}%")
