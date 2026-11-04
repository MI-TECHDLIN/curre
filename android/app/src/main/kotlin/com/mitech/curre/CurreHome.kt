package com.mitech.curre

import android.app.role.RoleManager
import android.content.Context

/**
 * Whether Curre is the phone's home screen right now. The hidden-app check
 * and notification quieting pause while another home screen is in use, so
 * leaving Curre really leaves it. When Android can't say, Curre assumes it
 * is still Home and keeps working as before.
 */
internal fun isCurreDefaultHome(context: Context): Boolean = try {
    val roleManager = context.getSystemService(RoleManager::class.java)
    roleManager == null ||
        !roleManager.isRoleAvailable(RoleManager.ROLE_HOME) ||
        roleManager.isRoleHeld(RoleManager.ROLE_HOME)
} catch (_: Exception) {
    true
}
