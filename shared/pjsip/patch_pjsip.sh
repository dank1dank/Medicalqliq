# Common environment for simulator and device

export PROJECTS_DIR=${HOME}/projects
export QLIQPROJECT_DIR=${PROJECTS_DIR}/qliqiphone
export PJPROJECT_DIR=${PROJECTS_DIR}/pjproject-2.1.0-qliq
cd ${PJPROJECT_DIR}
# Apply this when you need for the first time.
patch -p1  --verbose < ${QLIQPROJECT_DIR}/shared/pjsip/patches/pjsua_im_send_with_call_id.patch
patch -p1  --verbose < ${QLIQPROJECT_DIR}/shared/pjsip/patches/pjsua_keep_contact_instance_id_after_reg_error.patch
patch -p1  --verbose < ${QLIQPROJECT_DIR}/shared/pjsip/patches/pjsua_report_error_and_reregister_when_auth_required_for_message.patch
