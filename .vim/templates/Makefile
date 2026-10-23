CXX      := g++
CXXFLAGS := -std=c++20 -Wall -Wextra -g
LDLIBS   := $(shell pkg-config --libs gtest_main) -pthread
TARGET   := main
SRCS     := $(wildcard *.cpp)

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS) $(LDLIBS)

test: $(TARGET)
	timeout 10 ./$(TARGET)

clean:
	rm -f $(TARGET)

.PHONY: all test clean
