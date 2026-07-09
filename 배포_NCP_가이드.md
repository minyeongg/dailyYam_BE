# 🚀 NCP 서버에 dailyYam 배포하기 (초등학생용)

> 서버에서 **Docker로 통째로** 띄웁니다. MySQL·Redis·앱이 한 번에 켜져요.
> 명령어는 **복붙**하되, 맨 앞에 이상한 글자가 붙으면 직접 타이핑하세요.
> (이 가이드는 **Ubuntu 서버** 기준입니다.)

---

## 🧰 0단계. 준비물 체크

- [ ] NCP 서버 만들었음 (Ubuntu) + **공인 IP** 할당함
- [ ] 서버 메모리 **최소 4GB 권장** (2GB면 3단계에서 스왑 꼭 만들기)
- [ ] `.env`에 넣을 키들: `GMS_KEY`, `MFDS_SERVICE_KEY`, 비밀번호들
- [ ] 코드가 GitHub에 올라가 있음 (없으면 4단계 'scp' 방법 사용)

---

## 🔌 1단계. 서버에 접속하기

내 컴퓨터에서 (Git Bash 또는 PowerShell):

```bash
ssh root@공인IP
```

- `공인IP` 자리에 NCP에서 받은 IP를 넣으세요. (예: `ssh root@223.130.1.2`)
- 비밀번호는 NCP 콘솔에서 만든 관리자 비밀번호.

👉 서버 안으로 들어가지면 성공! (앞에 `root@...:~#` 같은 게 떠요)

> ⚠️ 접속이 안 되면? → NCP 콘솔에서 **ACG(방화벽)** 에 22번 포트가 열려 있는지 확인 (7단계 참고).

---

## 💾 2단계. (메모리 2GB면) 스왑 만들기 — 4GB 이상이면 건너뛰기

빌드할 때 메모리가 부족하면 실패해요. 가상 메모리(스왑)를 만들어 둡니다.

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

확인:
```bash
free -h
```
👉 `Swap` 줄에 4.0Gi 가 보이면 OK ✅

---

## 🐳 3단계. Docker 설치하기

```bash
sudo apt-get update
curl -fsSL https://get.docker.com | sudo sh
```

확인:
```bash
sudo docker compose version
```
👉 버전 숫자가 나오면 성공! ✅

---

## 📦 4단계. 코드 서버에 올리기

### 방법 A) GitHub에서 받기 (추천)
```bash
git clone 깃허브주소 dailyYam
cd dailyYam
```
- `깃허브주소` 자리에 본인 레포 주소 (예: `https://github.com/내아이디/dailyYam.git`)

### 방법 B) 내 컴퓨터에서 직접 복사 (GitHub 없을 때)
**내 컴퓨터** Git Bash에서 (서버 말고!):
```bash
cd /c/SSAFY/workspace
scp -r dailyYam root@공인IP:/root/dailyYam
```
그 다음 서버로 돌아와서:
```bash
cd /root/dailyYam
```

👉 `ls` 쳤을 때 `docker-compose.yml`, `Dockerfile` 이 보이면 성공! ✅

---

## 📝 5단계. `.env` 파일 만들기 (서버 안에서)

```bash
nano .env
```

편집 창이 열리면 아래를 붙여넣고 **값을 채우세요**:

```bash
DB_URL=jdbc:mysql://mysql:3306/dailyyam?serverTimezone=Asia/Seoul&characterEncoding=UTF-8
DB_USERNAME=root
DB_PASSWORD=여기_강한_비밀번호

JWT_SECRET=여기_긴_랜덤문자열
GMS_KEY=여기_GMS_키
MFDS_SERVICE_KEY=여기_식약처_Encoding_키

REDIS_HOST=redis
REDIS_PORT=6379
UPLOAD_DIR=uploads
```

- ⭐ **`REDIS_HOST`는 꼭 `redis`** (서버에선 localhost 아님! 도커끼리는 이름으로 통신해요)
- 저장: **Ctrl + O** → Enter → **Ctrl + X**

> 💡 `JWT_SECRET` 만들기: `openssl rand -base64 64` 실행해서 나온 글자 붙여넣기

---

## 🏗️ 6단계. 빌드하고 실행하기

```bash
sudo docker compose up -d --build
```

- ⏳ **처음엔 5~10분** 걸려요 (라이브러리 다운로드). 기다리세요.

진행 상황 보기:
```bash
sudo docker compose logs -f app
```
👉 **`Started DailyYamApplication`** 글자가 보이면 성공! ✅
(빠져나오려면 **Ctrl + C** — 앱은 계속 켜져 있어요)

상태 확인:
```bash
sudo docker compose ps
```
👉 mysql, redis, app **3개 다 `Up`** 이면 완벽 ✅

---

## 🔓 7단계. 방화벽(ACG) 포트 열기 — 아주 중요!

NCP 콘솔에서:
1. **Server → ACG** 메뉴
2. 내 서버의 ACG 선택 → **Inbound(들어오는) 규칙 추가**
3. 아래 두 개 추가:

| 프로토콜 | 포트 | 접근 소스 |
|---|---|---|
| TCP | 22 | 내 IP (SSH용) |
| TCP | 8080 | 0.0.0.0/0 (누구나 접속) |

👉 저장하면 바깥에서 접속 가능해져요.

---

## 🎉 8단계. 접속 확인 + AI 색인

내 컴퓨터 브라우저나 Git Bash에서:

```bash
curl http://공인IP:8080/api/conditions -H "Authorization: Bearer 토큰"
```

> 토큰은 `통합점검_체크리스트.md`의 4단계처럼, **공인IP로** 회원가입→로그인해서 받으면 됩니다.
> (체크리스트에서 `localhost` 만 `공인IP`로 바꾸면 그대로 다 테스트돼요!)

AI 코치 쓰려면 색인 한 번:
```bash
curl -X POST http://공인IP:8080/api/ai-coach/rag/reindex -H "Authorization: Bearer 토큰"
```
👉 `indexedChunks: 3` 나오면 RAG까지 OK ✅

---

## 🛠️ 자주 쓰는 명령 (서버에서)

| 하고 싶은 것 | 명령어 |
|---|---|
| 앱 로그 보기 | `sudo docker compose logs -f app` |
| 앱만 재시작 | `sudo docker compose restart app` |
| 전체 끄기 | `sudo docker compose down` |
| 전체 켜기 | `sudo docker compose up -d` |
| 상태 보기 | `sudo docker compose ps` |

---

## 🔄 코드 고친 뒤 다시 배포

```bash
cd /root/dailyYam   # 또는 코드 폴더
git pull            # (방법 A로 받았으면)
sudo docker compose up -d --build
```
👉 바뀐 부분만 다시 빌드하고 새로 띄워줘요.

---

## 🆘 안 될 때

| 증상 | 원인 | 해결 |
|---|---|---|
| 빌드 중 멈춤/`Killed` | 메모리 부족 | 2단계 스왑 만들기, 또는 서버 메모리 키우기 |
| 브라우저로 접속 안 됨 | ACG 8080 안 열림 | 7단계 다시 |
| `app`이 자꾸 꺼짐(Restarting) | `.env` 키 빠짐/Redis 문제 | `logs -f app` 으로 에러 확인 |
| `REDIS ... Connection refused` | `REDIS_HOST`가 localhost | `.env`에서 `REDIS_HOST=redis` 로 |
| DB 접속 에러 | `DB_URL`이 localhost | `DB_URL`의 호스트가 `mysql` 인지 확인 |
| AI 코치 에러 / 색인 0 | `GMS_KEY` 없음 | `.env`의 `GMS_KEY` 채우고 `restart` |

---

## 📌 기억할 핵심 3가지
1. 서버 안 `.env`에서는 **`REDIS_HOST=redis`, `DB_URL`의 호스트는 `mysql`** (도커 이름으로 통신).
2. **ACG에서 8080 열기** (안 열면 바깥에서 접속 불가).
3. 코드 바뀌면 **`git pull` → `docker compose up -d --build`**.

### ✅ 8단계까지 되면 인터넷에 배포 끝! 🎉
