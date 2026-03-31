## Pipeline CI на Node.js в GitHub Actions

**Цель** — учебный пример — простой проект, который можно склонировать, настроить и убедиться, что GitHub Actions работает

### 1. Создайте на **GitHub** новый публичный репозиторий `my-node-app` с `README.md`

    Склонируйте его себе, откройте в VS Code, и в интегрированном терминале VS Code создайте такую структуру будущего проекта:

Структура проекта
```
my-node-app/
├── .github/
│   └── workflows/
│       └── ci.yml
├── src/
│   └── index.js            # основной код
├── tests/
│   └── index.test.js       # тесты (Jest)
├── package.json            # зависимости и скрипты
├── Dockerfile
└── README.md
```

Структуру проекта можно сделать одной bash-командой, которая автоматически создаст всю структуру проекта:
```shell
mkdir -p .github/workflows src tests && \
touch .github/workflows/ci.yml src/index.js tests/index.test.js package.json Dockerfile README.md
```

### 2. Файл `package.json` (зависимости и скрипты)
```json
{
  "name": "my-node-app",
  "version": "1.0.0",
  "description": "Пример CI для Node.js",
  "main": "src/index.js",
  "scripts": {
    "test": "jest",
    "lint": "eslint src",
    "start": "node src/index.js"
  },
  "devDependencies": {
    "eslint": "^8.56.0",
    "jest": "^29.7.0"
  }
}
```

### 3. Файл `src/index.js` (основной код)
```javascript
function add(a, b) {
    return a + b;
}
function main() {
    console.log("Hello from Node.js app!");
}
if (require.main === module) {
    main();
}
module.exports = { add };
```

### 4. Файл `tests/index.test.js` (тесты)
```javascript
const { add } = require('../src/index');

test('adds 2 + 3 to equal 5', () => {
    expect(add(2, 3)).toBe(5);
});

test('adds -1 + 1 to equal 0', () => {
    expect(add(-1, 1)).toBe(0);
});

test('adds 0 + 0 to equal 0', () => {
    expect(add(0, 0)).toBe(0);
});
```

### 4. Файл `Dockerfile`
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
CMD ["node", "src/index.js"]
```

### 5. Файл `.github/workflows/ci.yml`
```yaml
name: CI for Node.js App

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  test:
    name: Lint & Test
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [18.x, 20.x, 22.x]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint with ESLint
        run: npm run lint

      - name: Test with Jest
        run: npm test

  docker-build:
    name: Build Docker Image (no push)
    runs-on: ubuntu-latest
    needs: test
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t my-node-app:test .
```

### 6. Проверить сборку онлайн

- Закоммитьте и запушите в строго в ветку `main` этот файл в ваш репозиторий
- Перейдите на вкладку **Actions** в вашем репозитории на **GitHub**. Вы увидите, как ваш **Workflow** запустился, а через минуту загорится **зеленая** галочка, которая означает, что все шаги прошли успешно

![Скрин](/content/DevOps/CI_CD/img)

### 7. Проверить сборку Docker-образа локально

На своём компьютере, находясь в папке `my-node-app` этого репозитория выполнить:

борка проекта в Docker-образ
```shell

```
Создание и запуск контейнера:
```shell

```

Вы увидите вывод:

![Hello from my Python app!](/content/DevOps/CI_CD/img)

Опционально вы можете зайти в созданный вами контейнер для ознакомления
```shell

```

> Если вы обнаружили ошибку в этом тексте - сообщите пожалуйста автору!

