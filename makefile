CC=gcc
CFLAGS=-I. -g -Wall -fsanitize=address,undefined -fno-omit-frame-pointer -std=c11 -pedantic

DEPS =
ODIR = ./obj
_OBJ = echoClient.o echoServer.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))
LIBS=

run_valgrind = valgrind --leak-check=full --log-file="./valgrind_log.txt" \
--show-leak-kinds=all --track-origins=yes --show-reachable=yes \
--trace-children=yes $1 && cat ./valgrind_log.txt

.PHONY: all valgrind_client valgrind_server profile_server profile_client clean

# default build test app
all: echoServer echoClient

echoServer: $(ODIR)/echoServer.o
	$(CC) -o $@ $^ $(CFLAGS) $(LIBS)
	chmod a+x $@

echoClient: $(ODIR)/echoClient.o
	$(CC) -o $@ $^ $(CFLAGS) $(LIBS)
	chmod a+x $@

# profile server
profile_server: target= echoServer
profile_server: CFLAGS+= -pg
profile_server: $(OBJ)
	$(CC) -o $(target) $^ $(CFLAGS) -pg $(LIBS)
	chmod a+x $(target)
	./$(target)
	gprof $(target) gmon.out > prof_output.txt
	cat prof_output.txt

# run valgrind
valgrind_server: echoServer
	$(call run_valgrind,./$<)

valgrind_client: echoClient
	$(call run_valgrind,./$<)

$(ODIR)/%.o: %.c $(DEPS) | $(ODIR)
	$(CC) -c -o $@ $< $(CFLAGS)

$(ODIR)/%.o: %.cpp $(DEPS) | $(ODIR)
	$(CXX) -c -o $@ $< $(CXXFLAGS)

$(ODIR):
	mkdir -p $@

clean:
	rm -f $(OBJ) gmon.out ./cpp echoClient echoServer
	rm -rf $(ODIR)