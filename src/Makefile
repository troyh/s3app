CGIBINDIR=../cgi-bin

all: $(CGIBINDIR)/list \
	 $(CGIBINDIR)/get.cgi

$(CGIBINDIR)/list: list.cc
	g++ -I/usr/include/libxml2/ $< -ls3 -o $@

$(CGIBINDIR)/get.cgi: get.cc
	g++ -I/usr/include/libxml2/ $< -ls3 -lcgicc -o $@

