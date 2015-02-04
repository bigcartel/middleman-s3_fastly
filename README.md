## middleman-s3_fastly

This is an embarrassingly simple tool. Essentially it simplifies setup and deployment
of static sites to s3 fronted by fastly. It configures s3_sync to push changed files
and reads stored configuration data from encrypted chef data bags. After deploy it
issues a purge request to fastly (we use a defined format for surrogate keys) to purge
text/html files immediately.

If you happen to use these tools and think this might be useful you are welcome to it.
