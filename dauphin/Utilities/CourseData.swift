import Foundation

let mockData: [Course] = [
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("08:10") ?? Date(),
               endTime: stringToTime("09:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("9:10") ?? Date(),
               endTime: stringToTime("10:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("10:10") ?? Date(),
               endTime: stringToTime("11:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("11:10") ?? Date(),
               endTime: stringToTime("12:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("13:10") ?? Date(),
               endTime: stringToTime("14:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("14:10") ?? Date(),
               endTime: stringToTime("15:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("15:10") ?? Date(),
               endTime: stringToTime("16:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("16:10") ?? Date(),
               endTime: stringToTime("17:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("17:10") ?? Date(),
               endTime: stringToTime("18:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("18:10") ?? Date(),
               endTime: stringToTime("19:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("19:10") ?? Date(),
               endTime: stringToTime("20:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("20:10") ?? Date(),
               endTime: stringToTime("21:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Math", room: "101", teacher: "Dr. Smith", time: "1",
               startTime: stringToTime("21:10") ?? Date(),
               endTime: stringToTime("22:00") ?? Date(),
               stdNo: "69",
               weekday: 1
              ),
        Course(name: "Science", room: "102", teacher: "Prof. Johnson", time: "4",
               startTime: stringToTime("11:10") ?? Date(),
               endTime: stringToTime("12:00") ?? Date(),
               stdNo: "69",
               weekday: 2
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("15:10") ?? Date(),
               endTime: stringToTime("16:00") ?? Date(),
               stdNo: "69",
               weekday: 2
              ),
        Course(name: "History", room: "103", teacher: "Ms. Davis", time: "6",
               startTime: stringToTime("13:10") ?? Date(),
               endTime: stringToTime("14:00") ?? Date(),
               stdNo: "69",
               weekday: 3
              ),
        Course(name: "Art", room: "104", teacher: "Mr. Brown", time: "7",
               startTime: stringToTime("14:10") ?? Date(),
               endTime: stringToTime("15:00") ?? Date(),
               stdNo: "69",
               weekday: 4
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("15:10") ?? Date(),
               endTime: stringToTime("16:00") ?? Date(),
               stdNo: "69",
               weekday: 4
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("15:10") ?? Date(),
               endTime: stringToTime("16:00") ?? Date(),
               stdNo: "69",
               weekday: 5
              ),
        Course(name: "Physical Education", room: "Gym", teacher: "Coach Green", time: "8",
               startTime: stringToTime("15:10") ?? Date(),
               endTime: stringToTime("16:00") ?? Date(),
               stdNo: "69",
               weekday: 6
              )
    
]
