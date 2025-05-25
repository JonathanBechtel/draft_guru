multi-platform-build-push:
	docker buildx build --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t jonathanbechtel/draft_guru:staging \
  --push .

dev-up:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

dev-build:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml build

dev-up-build:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build

dev-stop:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml stop

dev-down:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml down

stag-up:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml up

stag-build:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml build

stag-up-build:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml up --build

stag-up-d:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml up -d

stag-stop:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml stop

stag-down:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml down

stag-ps:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml ps

dev-ps:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml ps

dev-migrate:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec app mix ecto.migrate

dev-seed:
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml exec app mix run --no-start -e "DraftGuru.Release.seed()"

stag-migrate:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml \
		exec app bin/draft_guru eval "DraftGuru.Release.migrate()"

stag-seed:
	docker compose -f docker-compose.yml -f docker-compose.stag.yml \
		exec app bin/draft_guru eval "DraftGuru.Release.seed()"


