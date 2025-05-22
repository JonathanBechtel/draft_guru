multi-platform-build-push:
	docker buildx build --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t jonathanbechtel/draft_guru:staging \
  --push .

push-remote-staging:
	docker push jonathanbechtel/draft_guru:staging

dev-up:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

dev-build:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml build

dev-up-build:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build

.PHONY: bootstrap wait-db migrate seed

# Bring *everything* from zero‑>ready in one shot
bootstrap: build up wait-db migrate seed

# crude, portable  wait loop; exits when healthcheck says "running"
wait-db:
	@echo "⌛ waiting for Postgres…" ; \
	until docker-compose exec -T db pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB ; do \
	  sleep 2 ; \
	done && echo "✅ database is up"

dev-migrate:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec app mix ecto.migrate

dev-seed:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec app mix run --no-start -e "DraftGuru.Release.seed()"
