set -e

cd ../rift_ce_inspector
dart pub get
flutter build web --wasm
rm -rf ../rift/extension/devtools/build
cp -r build/web ../rift/extension/devtools/build
dart run devtools_extensions validate --package=../rift
