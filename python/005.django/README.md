# Django
Django는 파이썬으로 웹 애플리케이션을 개발하는 데 사용되는 강력한 웹 프레임워크입니다. 아래는 Django로 간단한 웹 애플리케이션을 만드는 기본 예제입니다. Django 프로젝트와 앱을 생성하고, 간단한 페이지를 만드는 과정을 안내합니다.

1. Django 설치:

   먼저 Django를 설치해야 합니다. 터미널 또는 명령 프롬프트에서 다음 명령을 실행하여 Django를 설치합니다:

   ```
   pip install Django
   ```

2. Django 프로젝트 생성:

   이제 Django 프로젝트를 생성합니다. 프로젝트는 웹 애플리케이션의 기반이 되는 구조를 설정합니다. 원하는 디렉토리에서 다음 명령을 실행합니다:

   ```
   django-admin startproject myproject
   ```

3. Django 앱 생성:

   Django 앱은 프로젝트 내에서 기능을 구성하는 데 사용됩니다. 다음 명령으로 앱을 생성합니다:

   ```
   cd myproject
   python manage.py startapp myapp
   ```

4. URL 설정:

   `myproject` 디렉토리 안의 `urls.py` 파일을 열고, 다음과 같이 URL 경로를 설정합니다:

   ```python
   from django.contrib import admin
   from django.urls import path, include

   urlpatterns = [
       path('admin/', admin.site.urls),
       path('', include('myapp.urls')),
   ]
   ```

5. 뷰(View) 생성:

   `myapp` 디렉토리 안의 `views.py` 파일을 열고, 간단한 뷰를 만듭니다:

   ```python
   from django.http import HttpResponse

   def hello(request):
       return HttpResponse("Hello, Django!")
   ```

6. URL 매핑:

   `myapp` 디렉토리 안에 `urls.py` 파일을 생성하고 다음과 같이 URL을 매핑합니다:

   ```python
   from django.urls import path
   from . import views

   urlpatterns = [
       path('', views.hello, name='hello'),
   ]
   ```

7. 데이터베이스 마이그레이션:

   데이터베이스를 설정하려면 다음 명령을 실행하여 데이터베이스 마이그레이션을 수행합니다:

   ```
   python manage.py migrate
   ```

8. 웹 서버 실행:

   다음 명령으로 내장 개발 서버를 시작합니다:

   ```
   python manage.py runserver
   ```

   서버가 실행되면 웹 브라우저에서 `http://127.0.0.1:8000/`을 열어 "Hello, Django!" 메시지를 확인할 수 있습니다.

이것은 Django의 기본 예제이며, Django를 더 깊이 이해하고 복잡한 웹 애플리케이션을 개발하려면 Django 공식 문서를 참고하는 것이 좋습니다. Django는 강력하고 확장 가능한 웹 프레임워크로서 다양한 기능과 기능을 제공합니다.