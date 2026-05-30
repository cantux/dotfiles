CXX      := g++
CXXFLAGS := -std=c++20 -Wall -Wextra -g
TARGET   := main
SRCS     := $(wildcard *.cpp)

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS)

clean:
	rm -f $(TARGET)

.PHONY: all clean
