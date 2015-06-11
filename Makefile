
build:
	docker build -t gliderlabs/pagebuilder .

serve:
	docker run --rm -it -p 8000:8000 -v $(PWD):/project gliderlabs/pagebuilder mkdocs serve
