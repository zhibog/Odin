ODIN=../../odin
PYTHON=$(shell which python3)

all: download_test_assets image_test compress_test strings_test hash_test

download_test_assets:
	$(PYTHON) download_assets.py

image_test:
	$(ODIN) run image/test_core_image.odin

compress_test:
	$(ODIN) run compress/test_core_compress.odin

strings_test:
	$(ODIN) run strings/test_core_strings.odin

hash_test:
	$(ODIN) run hash -out=test_hash -o:speed -no-bounds-check