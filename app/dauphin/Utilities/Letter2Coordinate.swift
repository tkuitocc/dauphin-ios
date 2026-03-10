import CoreLocation

struct L2GData: Identifiable {
    let code: String
    let name: String
    let coordinate: CLLocationCoordinate2D

    var id: String { code }

    init(code: String, name: String, coordinate: CLLocationCoordinate2D) {
        self.code = code
        self.name = name
        self.coordinate = coordinate
    }
}

let letterLocations: [String: L2GData] = [
    "A": L2GData(code: "A", name: "行政大樓", coordinate: .init(latitude: 25.175, longitude: 121.449)),
    "B": L2GData(code: "B", name: "商管大樓", coordinate: .init(latitude: 25.1765, longitude: 121.45)),
    "C": L2GData(
        code: "C", name: "鍾靈化學館", coordinate: .init(latitude: 25.1752, longitude: 121.449)),
    "E": L2GData(code: "E", name: "工學大樓", coordinate: .init(latitude: 25.1761, longitude: 121.452)),
    "ED": L2GData(
        code: "ED", name: "教育大樓", coordinate: .init(latitude: 25.1758, longitude: 121.453)),
    "F": L2GData(
        code: "F", name: "會文館", coordinate: .init(latitude: 25.17576, longitude: 121.44961)),
    "FL": L2GData(
        code: "FL", name: "外國語文大樓", coordinate: .init(latitude: 25.1749, longitude: 121.452)),
    "G": L2GData(code: "G", name: "工學館", coordinate: .init(latitude: 25.1763, longitude: 121.451)),
    "H": L2GData(code: "H", name: "宮燈教室", coordinate: .init(latitude: 25.1746, longitude: 121.449)),
    "HC": L2GData(
        code: "HC", name: "守謙國際會議中心", coordinate: .init(latitude: 25.1747, longitude: 121.448)),
    "I": L2GData(
        code: "I", name: "覺生綜合大樓", coordinate: .init(latitude: 25.1743, longitude: 121.4509)),
    "J": L2GData(
        code: "J", name: "麗澤國際學舍", coordinate: .init(latitude: 25.1763, longitude: 121.448)),
    "K": L2GData(
        code: "K", name: "建築館", coordinate: .init(latitude: 25.17644, longitude: 121.45102)),
    "L": L2GData(
        code: "L", name: "文學館", coordinate: .init(latitude: 25.17627, longitude: 121.44942)),
    "M": L2GData(
        code: "M", name: "海事博物館", coordinate: .init(latitude: 25.17618, longitude: 121.45041)),
    "N": L2GData(
        code: "N", name: "紹謨紀念游泳館", coordinate: .init(latitude: 25.1745, longitude: 121.447)),
    "O": L2GData(code: "O", name: "傳播O館", coordinate: .init(latitude: 25.1756, longitude: 121.449)),
    "Q": L2GData(code: "Q", name: "傳播Q館", coordinate: .init(latitude: 25.1756, longitude: 121.449)),
    "R": L2GData(
        code: "R", name: "學生活動中心", coordinate: .init(latitude: 25.1748, longitude: 121.45)),
    "S": L2GData(
        code: "S", name: "騮先紀念科學館", coordinate: .init(latitude: 25.1754, longitude: 121.448)),
    "SG": L2GData(
        code: "SG", name: "紹謨紀念體育館", coordinate: .init(latitude: 25.1762, longitude: 121.449)),
    "T": L2GData(
        code: "T", name: "驚聲紀念大樓", coordinate: .init(latitude: 25.1755, longitude: 121.451)),
    "U": L2GData(
        code: "U", name: "覺生紀念圖書館", coordinate: .init(latitude: 25.174833, longitude: 121.450972)),
    "V": L2GData(
        code: "V", name: "視聽教育館", coordinate: .init(latitude: 25.17503, longitude: 121.44943)),
    "XC": L2GData(
        code: "XC", name: "五虎崗綜合球場", coordinate: .init(latitude: 25.17552, longitude: 121.45366)),
    "Z": L2GData(
        code: "Z", name: "松濤館", coordinate: .init(latitude: 25.174967, longitude: 121.452078)),
    "ZZZ": L2GData(
        code: "ZZZ", name: "書卷廣場", coordinate: .init(latitude: 25.17553, longitude: 121.45063)),
]

private let defaultCoord = CLLocationCoordinate2D(latitude: 25.0478, longitude: 121.5170)

let campusLocations: [L2GData] = letterLocations.values.sorted { lhs, rhs in
    lhs.code.localizedStandardCompare(rhs.code) == .orderedAscending
}

func letterToCoordinate(for letter: String) -> CLLocationCoordinate2D {
    letterLocations[letter]?.coordinate ?? defaultCoord
}
