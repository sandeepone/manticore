FROM alpine:3.11

RUN set -ex; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		git \
		cmake \
		make \
		g++ \
		mariadb-dev \
		bison \
		flex-dev \
	; \
	\
	git clone --branch=3.3.0  --depth=1 https://github.com/manticoresoftware/manticore.git /usr/src/manticore; \
	\
	mkdir -p /usr/src/manticore/build; \
	cd /usr/src/manticore/build; \
	\
	cmake -DDISABLE_TESTING=ON -DUSE_GALERA=OFF -DWITH_STEMMER_FORCE_STATIC=1 -DCMAKE_BUILD_TYPE=Release /usr/src/manticore; \
	make --jobs="$(nproc)"; \
	make install; \
	\
	rm -r /usr/src/manticore; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .manticore-rundeps $runDeps; \
	\
	apk del .build-deps
  CMD ["/usr/local/usr/bin/searchd", "--nodetach"]
