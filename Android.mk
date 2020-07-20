# Google Android makefile for curl and libcurl
#
# This file is an updated version of Dan Fandrich's Android.mk, meant to build
# curl for ToT android with the android build system.

LOCAL_PATH:= $(call my-dir)

# Curl needs a version string.
# As this will be compiled on multiple platforms, generate a version string from
# the build environment variables.
version_string := "Android $(PLATFORM_VERSION) $(TARGET_ARCH_VARIANT)"

curl_CFLAGS := -Wpointer-arith -Wwrite-strings -Wunused -Winline \
	-Wnested-externs -Wmissing-declarations -Wmissing-prototypes -Wno-long-long \
	-Wfloat-equal -Wno-multichar -Wsign-compare -Wno-format-nonliteral \
	-Wendif-labels -Wstrict-prototypes -Wdeclaration-after-statement \
	-Wno-system-headers -DHAVE_CONFIG_H -DOS='$(version_string)'

curl_includes := \
	$(LOCAL_PATH)/include/ \
	$(LOCAL_PATH)/lib \
	external/boringssl/include \
	external/c-ares \
	external/zlib/src

#########################
# Build the libcurl static library

include $(CLEAR_VARS)
include $(LOCAL_PATH)/lib/Makefile.inc

LOCAL_SRC_FILES := $(addprefix lib/,$(CSOURCES))
LOCAL_C_INCLUDES := $(curl_includes)
LOCAL_CFLAGS := $(curl_CFLAGS)

LOCAL_MODULE:= libcurl
LOCAL_MODULE_TAGS := optional

include $(BUILD_STATIC_LIBRARY)

#########################
# Build the libcurl shared library

include $(CLEAR_VARS)
include $(LOCAL_PATH)/lib/Makefile.inc

LOCAL_SRC_FILES := $(addprefix lib/,$(CSOURCES))
LOCAL_C_INCLUDES := $(curl_includes)
LOCAL_CFLAGS := $(curl_CFLAGS)

LOCAL_MODULE:= libcurl
LOCAL_MODULE_TAGS := optional
LOCAL_SHARED_LIBRARIES := libcrypto libssl libz libcares

LOCAL_REQUIRED_MODULES := ca-bundle.crt

include $(BUILD_SHARED_LIBRARY)

#########################
# Build the curl binary

include $(CLEAR_VARS)
include $(LOCAL_PATH)/src/Makefile.inc
LOCAL_SRC_FILES := $(addprefix src/,$(CURL_CFILES))

LOCAL_MODULE := curl
LOCAL_MODULE_TAGS := optional
LOCAL_STATIC_LIBRARIES := libcurl
LOCAL_SHARED_LIBRARIES := libcrypto libssl libz libcares


LOCAL_C_INCLUDES := $(curl_includes)

# This may also need to include $(CURLX_CFILES) in order to correctly link
# if libcurl is changed to be built as a dynamic library
LOCAL_CFLAGS := $(curl_CFLAGS)

include $(BUILD_EXECUTABLE)

##################################
# Build the ca-bundle.crt for libcurl

include $(CLEAR_VARS)

-include prebuilt-b2g/Android.mk
LOCAL_MODULE := ca-bundle.crt
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT)/etc
include $(BUILD_PREBUILT)

MK_CA_BUNDLE := $(ANDROID_BUILD_TOP)/$(LOCAL_PATH)/lib/mk-ca-bundle.pl
CERTDATA_FILE := file://$(ANDROID_BUILD_TOP)/gecko/security/nss/lib/ckfw/builtins/certdata.txt

$(LOCAL_BUILT_MODULE):
	@mkdir -p $(@D)
ifneq ($(PREBUILT_CA_BUNDLE),)
	@cp $(PREBUILT_CA_BUNDLE) -f $@
else
	@perl $(MK_CA_BUNDLE) -d $(CERTDATA_FILE) -n -f $(ANDROID_BUILD_TOP)/$@
endif
