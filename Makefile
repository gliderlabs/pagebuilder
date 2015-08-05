
build:
	docker build -t gliderlabs/pagebuilder .

serve:
	docker run --rm -it -p 8000:8000 -v $(PWD):/work gliderlabs/pagebuilder mkdocs serve
