CGIBINDIR=../cgi-bin

all: $(CGIBINDIR)/list \
	 $(CGIBINDIR)/get.cgi \
	 $(CGIBINDIR)/create_bucket.cgi \

$(CGIBINDIR)/list: list.cc
	g++ -I/usr/include/libxml2/ $< -ls3 -o $@

$(CGIBINDIR)/get.cgi: get.cc Config.o
	g++ -I/usr/include/libxml2/ $^ -ls3 -lcgicc -o $@

$(CGIBINDIR)/create_bucket.cgi: create_bucket.cc Config.o
	g++ -I/usr/include/libxml2/ $^ -ls3 -lcgicc -o $@

