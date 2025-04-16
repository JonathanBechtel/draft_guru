up:
	docker-compose up

down:
	docker-compose down

build:
	docker-compose build

rebuild:
	docker-compose up --build

dev:
	export $(cat .env.dev | xargs) && docker-compose up