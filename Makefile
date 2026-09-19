deploy:
	flutter pub get
	flutter pub upgrade
	dart run isolate_manager:generate
	flutter build web --no-wasm-dry-run
	firebase -P harcapp deploy
