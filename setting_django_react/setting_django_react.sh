#!/bin/bash

# source ./setting_django_react.sh [django_project_name]
# 이부분 좀더 강화 되어야함
if [$1 -n $1];then
    echo "django project name을 입력하세요"
    exit 2
fi

mkdir backend frontend
# # 가상환경 세팅
cd backend

sudo apt-get update
sudo apt-get install -y make build-essential libssl-dev \
zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev \
git python3-pip


pip install virtualenv
virtualenv venv
. ./venv/bin/activate

pip install django django-cors-headers djangorestframework
django-admin startproject $1 .
python manage.py startapp api

# backend setting
# 1. .secrets.json setting
temp=$(grep "SECRET_KEY" $1/settings.py)
val=$(echo "${temp:13}" | sed 's/./"/' | sed 's/..$/"/')
echo -e "{\n\t\"SECRET_KEY\" : ${val} \n}" > .secrets.json

# 2. settings.py 설정 변경

# 2.1secrets.json에서 가져오도록 변경하기
sed -i "12s/.*/import os, json, sys\n/g" $1/settings.py #줄수 +1
sed -i "22s/.*/SECRET_BASE_FILE = os.path.join(BASE_DIR, '.secrets.json')/g" $1/settings.py
sed -i "23s/.*/secrets = json.loads(open(SECRET_BASE_FILE).read())/g" $1/settings.py
sed -i "24s/.*/for key, value in secrets.items():/g" $1/settings.py
sed -i "25s/.*/    setattr(sys.modules[__name__], key, value)\n/g" $1/settings.py #줄수 +1 (합+2)

# 2.2 instanse_app add
sed -i "35s/.*/INSTALLED_APPS = [\n/g" $1/settings.py
sed -i "36s/.*/    'rest_framework',\n/g" $1/settings.py
sed -i "37s/.*/    'corsheaders',/g" $1/settings.py

# 2.3 cors middleware 추가
sed -i "46s/.*/MIDDLEWARE = [\n/g" $1/settings.py #줄수 +1 (+3)
sed -i "47s/.*/    'corsheaders.middleware.CorsMiddleware',/g" $1/settings.py

# 2.4 add static_setting 
sed -i "121s/.*/STATICFILES_DIRS = [\n,/g" $1/settings.py
sed -i "122s/.*/    os.path.join(BASE_DIR, '..', 'frontend', 'build', 'static'),\n,/g" $1/settings.py
sed -i "123s/.*/]\n,/g" $1/settings.py
sed -i "124s/.*/STATIC_ROOT = os.path.join(BASE_DIR,'static')/g" $1/settings.py

# 2.5 add cors setting value
echo "CORS_ORIGIN_WHITELIST = [" >> $1/settings.py
echo "    'http://localhost:3000'," >> $1/settings.py
echo "    'http://127.0.0.1:8000'," >> $1/settings.py
echo "]" >> $1/settings.py

echo CORS_ALLOW_CREDENTIALS = True >> $1/settings.py

# 3. backend/api에 views, utils, serialzier,tests 폴더 만들기
mkdir api/Views api/Serialzier api/tests api/Utils

# 4. Front react settings
cd ../frontend
curl -sL deb.nodesource.com/setup_lts.x | sudo -E bash - 
sudo apt-get install -y nodejs

# npm 설치
sudo apt install -y aptitude
sudo aptitude install -y npm

# react front setting
npx create-react-app .
rm -rf .git

cd ..
# 5 create .gitignore
touch .gitignore
echo "react와 django 세팅이 완료 되었습니다."
# 깃세팅은 보류...
#add .gitignore는 https://www.toptal.com/developers/gitignore 로 가서 해줘!
