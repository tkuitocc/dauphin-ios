//
//  Constants.swift
//  campuspass_ios
//
//  Created by \u8b19 on 11/17/24.
//

import Foundation

enum Constants {
    static let loggerSubsystem = CourseLogger.subsystem
    static let appGroupSuiteName = "group.club.ntut.tkuitocc.dauphin"

    static let ssoTokenKey = "ssoStuNo"
    static let isLoggedInKey = "isLoggedIn"
    static let loginSuccessNotification = "LoginSuccess"
    static let courses = "Courses"
    static let showEnglishCourseName = "showEnglishCourseName"
    static let showEnglishTeacherName = "showEnglishTeacherName"

    static let keychainAESKey = "AES256KEY"
    static let keychainAESIV = "AES256IV"

    static let courseAPIEndpoint = "https://ilifeapi.az.tku.edu.tw/api/ilifeStuClassApi"
    static let eventXMLAPIEndpoint = "https://ilifeapi.az.tku.edu.tw/data/xml_cal.ashx"
    static let ssoLoginURL = "https://sso.tku.edu.tw/ilife/CoWork/AndroidSsoLogin.cshtml"
}

extension Notification.Name {
    static let loginSuccess = Notification.Name(Constants.loginSuccessNotification)
}
