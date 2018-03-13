#FROM wsoyinka/todobackend-base:latest
FROM wsoyinka/remindmebackend-base:latest
LABEL maintainer="wale soyinka <wsoyinka@gmail.com>"



COPY target /wheelhouse

RUN . /appenv/bin/activate && \
 pip install --no-index -f /wheelhouse todobackend && \
 rm -rf /wheelhouse 

