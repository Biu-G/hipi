################################################################################
#
# Copyright 1993-2020 NVIDIA Corporation.  All rights reserved.
#
# NOTICE TO USER:   
#
# This source code is subject to NVIDIA ownership rights under U.S. and 
# international Copyright laws.  
#
# NVIDIA MAKES NO REPRESENTATION ABOUT THE SUITABILITY OF THIS SOURCE 
# CODE FOR ANY PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR 
# IMPLIED WARRANTY OF ANY KIND.  NVIDIA DISCLAIMS ALL WARRANTIES WITH 
# REGARD TO THIS SOURCE CODE, INCLUDING ALL IMPLIED WARRANTIES OF 
# MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.   
# IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL, 
# OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS 
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE 
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE 
# OR PERFORMANCE OF THIS SOURCE CODE.  
#
# U.S. Government End Users.  This source code is a "commercial item" as 
# that term is defined at 48 C.F.R. 2.101 (OCT 1995), consisting  of 
# "commercial computer software" and "commercial computer software 
# documentation" as such terms are used in 48 C.F.R. 12.212 (SEPT 1995) 
# and is provided to the U.S. Government only as a commercial end item.  
# Consistent with 48 C.F.R.12.212 and 48 C.F.R. 227.7202-1 through 
# 227.7202-4 (JUNE 1995), all U.S. Government End Users acquire the 
# source code with only those rights set forth herein.
#
################################################################################
#
#  findnvsci.mk is used to find the NVSCI Libraries and headers
#
################################################################################

# Determine OS platform and unix distribution
ifeq ("$(TARGET_OS)","linux")
   # first search lsb_release
   DISTRO  := $(shell lsb_release -i -s 2>/dev/null | tr "[:upper:]" "[:lower:]")
   ifeq ("$(DISTRO)","")
     # second search and parse /etc/issue
     DISTRO := $(shell awk '{print $$1}' /etc/issue | tr -d "[:space:]" | sed -e "/^$$/d" | tr "[:upper:]" "[:lower:]")
     # ensure data from /etc/issue is valid
     ifeq (,$(filter $(DISTRO),ubuntu fedora red rhel centos suse))
       DISTRO := 
     endif
     ifeq ("$(DISTRO)","")
       # third, we can search in /etc/os-release or /etc/{distro}-release
       DISTRO := $(shell awk '/ID/' /etc/*-release | sed 's/ID=//' | grep -v "VERSION" | grep -v "ID" | grep -v "DISTRIB")
     endif
   endif
endif

ifeq ("$(TARGET_OS)","linux")
    # $(info) >> findegl.mk -> LINUX path <<<)
    # Each set of Linux Distros have different paths for where to find their OpenGL libraries reside
    UBUNTU = $(shell echo $(DISTRO) | grep -i ubuntu      >/dev/null 2>&1; echo $$?)
    FEDORA = $(shell echo $(DISTRO) | grep -i fedora      >/dev/null 2>&1; echo $$?)
    RHEL   = $(shell echo $(DISTRO) | grep -i 'red\|rhel' >/dev/null 2>&1; echo $$?)
    CENTOS = $(shell echo $(DISTRO) | grep -i centos      >/dev/null 2>&1; echo $$?)
    SUSE   = $(shell echo $(DISTRO) | grep -i 'suse\|sles' >/dev/null 2>&1; echo $$?)
    ifeq ("$(UBUNTU)","0")
      ifeq ($(HOST_ARCH)-$(TARGET_ARCH),x86_64-armv7l)
        GLPATH := /usr/arm-linux-gnueabihf/lib
        GLLINK := -L/usr/arm-linux-gnueabihf/lib
        ifneq ($(TARGET_FS),) 
          GLPATH += $(TARGET_FS)/usr/lib/arm-linux-gnueabihf
          GLLINK += -L$(TARGET_FS)/usr/lib/arm-linux-gnueabihf
        endif
      else ifeq ($(HOST_ARCH)-$(TARGET_ARCH),x86_64-aarch64)
        GLPATH := /usr/aarch64-linux-gnu/lib
        GLLINK := -L/usr/aarch64-linux-gnu/lib
        ifneq ($(TARGET_FS),)
          GLPATH += $(TARGET_FS)/usr/lib
          GLPATH += $(TARGET_FS)/usr/lib/aarch64-linux-gnu
          GLLINK += -L$(TARGET_FS)/usr/lib/aarch64-linux-gnu
        endif 
      else
        UBUNTU_PKG_NAME = $(shell which dpkg >/dev/null 2>&1 && dpkg -l 'nvidia-*' | grep '^ii' | awk '{print $$2}' | head -1)
        ifneq ("$(UBUNTU_PKG_NAME)","")
          GLPATH    ?= /usr/lib/$(UBUNTU_PKG_NAME)
          GLLINK    ?= -L/usr/lib/$(UBUNTU_PKG_NAME)
        endif
        DFLT_PATH ?= /usr/lib
      endif
    endif
    ifeq ("$(SUSE)","0")
      GLPATH    ?= /usr/X11R6/lib64
      GLLINK    ?= -L/usr/X11R6/lib64
      DFLT_PATH ?= /usr/lib64
    endif
    ifeq ("$(FEDORA)","0")
      GLPATH    ?= /usr/lib64/nvidia
      GLLINK    ?= -L/usr/lib64/nvidia
      DFLT_PATH ?= /usr/lib64
    endif
    ifeq ("$(RHEL)","0")
      GLPATH    ?= /usr/lib64/nvidia
      GLLINK    ?= -L/usr/lib64/nvidia
      DFLT_PATH ?= /usr/lib64
    endif
    ifeq ("$(CENTOS)","0")
      GLPATH    ?= /usr/lib64/nvidia
      GLLINK    ?= -L/usr/lib64/nvidia
      DFLT_PATH ?= /usr/lib64
    endif

  NVSCIBUFLIB  := $(shell find -L $(GLPATH) $(DFLT_PATH) -name libnvscibuf.so    -print 2>/dev/null)
  NVSCISYNCLIB  := $(shell find -L $(GLPATH) $(DFLT_PATH) -name libnvscisync.so    -print 2>/dev/null)

  ifeq ("$(NVSCIBUFLIB)","")
      $(info >>> WARNING - libnvscibuf.so not found, please install libnvscibuf.so <<<)
      SAMPLE_ENABLED := 0
  endif

  ifeq ("$(NVSCISYNCLIB)","")
      $(info >>> WARNING - libnvscisync.so not found, please install libnvscisync.so <<<)
      SAMPLE_ENABLED := 0
  endif

  HEADER_SEARCH_PATH ?= $(TARGET_FS)/usr/include
  ifeq ($(HOST_ARCH)-$(TARGET_ARCH)-$(TARGET_OS),x86_64-armv7l-linux)
      HEADER_SEARCH_PATH += /usr/arm-linux-gnueabihf/include
  else ifeq ($(HOST_ARCH)-$(TARGET_ARCH)-$(TARGET_OS),x86_64-aarch64-linux)
      HEADER_SEARCH_PATH += /usr/aarch64-linux-gnu/include
  endif

  NVSCIBUFHEADER  := $(shell find -L $(HEADER_SEARCH_PATH) -name nvscibuf.h -print 2>/dev/null)
  NVSCISYNCHEADER  := $(shell find -L $(HEADER_SEARCH_PATH) -name nvscisync.h -print 2>/dev/null)

  ifeq ("$(NVSCIBUFHEADER)","")
      $(info >>> WARNING - nvscibuf.h not found, please install nvscibuf.h <<<)
      SAMPLE_ENABLED := 0
  endif
  ifeq ("$(NVSCISYNCHEADER)","")
      $(info >>> WARNING - nvscisync.h not found, please install nvscisync.h <<<)
      SAMPLE_ENABLED := 0
  endif
else
endif

