CXX = g++
CXXFLAGS := -g -O2 -Wall -I. 
OBJS = $(subst .cc,.o,$(wildcard *.cc))
BIN = apt-extracttemplates
LIBS := -lapt-pkg 

all: $(BIN)

%.o: %.cc
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BIN): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(BIN) $(OBJS) $(LIBS)

clean:
	-rm -f $(BIN)
	-rm -f *.o *~
