cmake_minimum_required(VERSION 2.8)
project(index_perf)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -W -Wall -Wextra -pthread -std=c++14 -Wl,--no-as-needed")
#set(CMAKE_VERBOSE_MAKEFILE on)

set(CMAKE_FIND_LIBRARY_SUFFIXES .a ${CMAKE_FIND_LIBRARY_SUFFIXES})

find_library(BOOST_PROGRAM_OPTIONS_LIBRARY boost_program_options)
find_library(BOOST_SYSTEM_LIBRARY boost_system)
find_library(BOOST_THREAD_LIBRARY boost_thread)
find_library(ELLIPTICS_LIBRARY elliptics)
find_library(ELLIPTICS_CPP_LIBRARY elliptics_cpp)
find_library(ELLIPTICS_CLIENT_LIBRARY elliptics_client)

set(LIBRARIES
  ${BOOST_PROGRAM_OPTIONS_LIBRARY}
  ${BOOST_SYSTEM_LIBRARY}
  ${BOOST_THREAD_LIBRARY}
  ${ELLIPTICS_LIBRARY}
  ${ELLIPTICS_CPP_LIBRARY}
  ${ELLIPTICS_CLIENT_LIBRARY})

aux_source_directory(. SRC_LIST)
add_executable(${PROJECT_NAME} ${SRC_LIST})
target_link_libraries(${PROJECT_NAME} ${LIBRARIES})
