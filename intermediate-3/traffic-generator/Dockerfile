FROM curlimages/curl
COPY generate.sh /generate.sh
USER root
RUN chmod +x /generate.sh
USER curl_user
CMD ["/generate.sh"]
