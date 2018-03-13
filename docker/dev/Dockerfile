## Dev Image used for running unit and integration tests

#FROM wsoyinka/todobackend-base:latest
FROM wsoyinka/remindmebackend-base:latest

LABEL maintainer="wale soyinka <wsoyinka@gmail.com>"

# install dev/build dependencies

RUN	apt-get update && \ 
	apt-get -y install python-dev \
	libmysqlclient-dev \
	build-essential

# Activate venv and install wheel support
RUN  . /appenv/bin/activate && \
	pip install wheel --upgrade

# Inject various environment variables into container
ENV WHEELHOUSE=/wheelhouse PIP_WHEEL_DIR=/wheelhouse PIP_FIND_LINKS=/wheelhouse XDG_CACHE_HOME=/cache

# Build artifacts output by WHEEL are stored here
VOLUME /wheelhouse
VOLUME /build

# Test results are stored here
VOLUME /reports

# Entrypoint test scripts
COPY scripts/test.sh /usr/local/bin/test.sh

RUN chmod +x /usr/local/bin/test.sh

ENTRYPOINT ["test.sh"]
CMD [ "python", "manage.py", "test", "--noinput" ]

COPY src  /application
WORKDIR /application
