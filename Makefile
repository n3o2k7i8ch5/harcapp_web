deploy:
	flutter pub get
	flutter pub upgrade
	dart run isolate_manager:generate
	flutter build web
	firebase -P harcapp deploy
