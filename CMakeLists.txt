# Copyright 2016 Axel Huebl
#
# "New" / "Revised" 3-Clause BSD License

################################################################################
# Required cmake version
################################################################################

cmake_minimum_required(VERSION 3.0.2) #3.1.0)


################################################################################
# Project 
################################################################################

project(BoostNVCC)

# set helper path to find libraries and packages
list(APPEND CMAKE_PREFIX_PATH "$ENV{CUDA_ROOT}")
list(APPEND CMAKE_PREFIX_PATH "$ENV{BOOST_ROOT}")
# Add from environment after specific env vars
list(APPEND CMAKE_PREFIX_PATH "$ENV{CMAKE_PREFIX_PATH}")
# Last add generic system path to the end (as last fallback)
list(APPEND "/usr/lib/x86_64-linux-gnu/")


################################################################################
# C++ Standard
################################################################################

set(CMAKE_CXX_STANDARD 11)


################################################################################
# Find CUDA 
################################################################################

find_package(CUDA $ENV{CUDA_VERSION} REQUIRED)

set(CUDA_ARCH sm_20 CACHE STRING "Set GPU architecture")
set(CUDA_NVCC_FLAGS ${CUDA_NVCC_FLAGS} -arch=${CUDA_ARCH})


################################################################################
# Find Boost
################################################################################

find_package(Boost $ENV{BOOST_VERSION} REQUIRED
             COMPONENTS program_options regex filesystem system thread math_tr1)

include_directories(SYSTEM ${Boost_INCLUDE_DIRS})
set(LIBS ${LIBS} ${Boost_LIBRARIES})

option(BOOST_APPLY_FIXES
       "Applies fixes to a release of Boost" OFF)

if(BOOST_APPLY_FIXES)

# Boost 1.55 added support for a define that makes result_of look for
# the result<> template and falls back to decltype if none is found. This is
# great for the transition from the "wrong" usage to the "correct" one as
# both can be used. But:
# 1) Cannot be used in 7.0 due to nvcc bug:
#    http://stackoverflow.com/questions/31940457/
# 2) Requires C++11 enabled as there is no further check in boost besides
#    the version check of nvcc
if( (NOT CUDA_VERSION VERSION_EQUAL 7.0) AND (CMAKE_CXX_STANDARD EQUAL 11) )
    add_definitions(-DBOOST_RESULT_OF_USE_TR1_WITH_DECLTYPE_FALLBACK)
else()
    # Fallback
    add_definitions(-DBOOST_RESULT_OF_USE_TR1)
endif()

# work-arounds and known issues
if( (Boost_VERSION EQUAL 106000) AND
    (CMAKE_CXX_STANDARD EQUAL 98) )
    # Boost Bug https://svn.boost.org/trac/boost/ticket/11852
    message(FATAL_ERROR "Boost: Please use a C++11 enabled Compiler with "
                        "`-std=c++11` when compiling with Boost 1.60.0")
endif()

# Boost 1.60.0 and CUDA releases prior to 7.5 fail on variadic templates
# when used with C++11
if( (Boost_VERSION EQUAL 106000) AND
    (CUDA_VERSION VERSION_LESS 7.5) AND
    (NOT CMAKE_CXX_STANDARD EQUAL 98) )
    # Boost Bug https://svn.boost.org/trac/boost/ticket/11897
    message(STATUS "Boost: Disable variadic templates")
    add_definitions(-DBOOST_NO_CXX11_VARIADIC_TEMPLATES)
endif()

endif(BOOST_APPLY_FIXES)


################################################################################
# Warnings
################################################################################

# GNU
if(CMAKE_COMPILER_IS_GNUCXX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unknown-pragmas")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-parameter")
    # new warning in gcc 4.8 (flag ignored in previous version)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-unused-local-typedefs")
# ICC
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DBOOST_NO_VARIADIC_TEMPLATES")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DBOOST_NO_CXX11_VARIADIC_TEMPLATES")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DBOOST_NO_FENV_H")
# PGI
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "PGI")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Minform=inform")
endif()


################################################################################
# Compile & Link PIConGPU
################################################################################

file(GLOB CUDASRCFILES "*.cu")
file(GLOB SRCFILES "*.cpp")

cuda_add_executable(main
    ${CUDASRCFILES}
    ${SRCFILES}
)

target_link_libraries(main ${LIBS} ${CUDA_CUDART_LIBRARY} z m)
