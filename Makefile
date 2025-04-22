IMAGE=jonathanbechtel/draft_guru
TAG?=dev

build-remote:
	docker build -t $(IMAGE):$(TAG) .

push-remote:
	docker push $(IMAGE):$(TAG)

up:
	docker-compose up

down:
	docker-compose down

build:
	docker-compose build

rebuild:
	docker-compose up --build

.PHONY: bootstrap wait-db migrate seed

# Bring *everything* from zero‑>ready in one shot
bootstrap: build up wait-db migrate seed

build:
	docker-compose build

up:
	docker-compose up -d

# crude, portable  wait loop; exits when healthcheck says "running"
wait-db:
	@echo "⌛ waiting for Postgres…" ; \
	until docker-compose exec -T db pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB ; do \
	  sleep 2 ; \
	done && echo "✅ database is up"

migrate:
	docker-compose exec app /app/bin/draft_guru eval "DraftGuru.Release.migrate()"

seed:
	docker-compose exec app /app/bin/draft_guru eval "DraftGuru.Release.seed()"
