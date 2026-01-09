deploy:
	flutter pub get
	flutter pub upgrade
	flutter build web
	firebase -P harcapp deploy
