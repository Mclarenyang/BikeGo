//
//  RoadPlanViewController.swift
//  BikeDemo
//
//  Created by 杨键 on 2018/3/22.
//  Copyright © 2018年 mclarenYang. All rights reserved.
//

import UIKit
import Hero

class RoadPlanViewController: UIViewController {
    
    //导航终点
    var endPointCoordinate = CLLocationCoordinate2D(latitude: 111, longitude: 122)
    var startPoi = AMapNaviPoint()
    //地图
    let mapView = MAMapView(frame: UIScreen.main.bounds)
    //导航视图
    let rideView = AMapNaviRideView(frame: UIScreen.main.bounds)
    //路线管理
    let rideManager = AMapNaviRideManager()
    //实例化一个Dash用于调用记录方法
    let DashVC = DashBoardViewController()
    //管理info
    var ifInfoGot = true

    @IBOutlet weak var BackBtn: UIButton!
    @IBOutlet weak var NaviBtn: UIButton!
    @IBOutlet weak var RodeInfoView: UIView!
    @IBOutlet weak var TimeLabel: UILabel!
    @IBOutlet weak var DistanceLabel: UILabel!
    
    @IBAction func StartNavi(_ sender: Any) {
        initRideView()
        addRepresent()
        rideManager.startGPSNavi()
        DashVC.ifDashVCAppear = false
        DashVC.startRecordRideData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hero.isEnabled = true
        
        //地图
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
        mapView.isRotateEnabled = true
        mapView.showsCompass = false
        mapView.zoomLevel = 15
        mapView.touchPOIEnabled = true
        self.view.addSubview(mapView)
        
        mapView.addSubview(RodeInfoView)
        mapView.addSubview(BackBtn)
        
        //路线规划
        rideManager.delegate = self
        let endPoi = AMapNaviPoint.location(withLatitude: CGFloat(endPointCoordinate.latitude), longitude: CGFloat(endPointCoordinate.longitude))
        if endPoi != nil {rideManager.calculateRideRoute(withStart: startPoi, end: endPoi!)}
        
        if rideManager.calculateRideRoute(withStart: startPoi, end: endPoi!) == false{
            ifInfoGot = false
            self.TimeLabel.text = ""
            self.DistanceLabel.text = "点击导航"
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //视图消失后销毁
    override func viewWillDisappear(_ animated: Bool) {
        rideManager.delegate = nil
        rideManager.removeDataRepresentative(rideView)
    }
    
    func initRideView() {
        rideView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        rideView.showSensorHeading = true
        rideView.delegate = self
        
        self.view.addSubview(rideView)
    }
    
    func addRepresent() {
        
        rideManager.allowsBackgroundLocationUpdates = true
        rideManager.pausesLocationUpdatesAutomatically = false
        rideManager.isUseInternalTTS = true
        //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
        rideManager.addDataRepresentative(rideView)
    }
    
    func loadRoadInfoView(road: AMapNaviRoute){
        TimeLabel.text = String(format: "%.1f", road.routeTime / 60)  + " min"
        DistanceLabel.text = String(format: "%.1f", road.routeLength / 1000)  + " km"
        RodeInfoView.addSubview(TimeLabel)
        RodeInfoView.addSubview(DistanceLabel)
        RodeInfoView.addSubview(NaviBtn)
    }

}

extension RoadPlanViewController: AMapNaviRideManagerDelegate, MAMapViewDelegate, AMapNaviRideViewDelegate {
    
    func rideManager(onCalculateRouteSuccess rideManager: AMapNaviRideManager) {
        NSLog("CalculateRouteSuccess")
        //绘制路线
        let roadArray = rideManager.naviRoute?.routeCoordinates
        var lineCoordinates: [CLLocationCoordinate2D] = []
        if roadArray != nil{
            for index in roadArray!{
                lineCoordinates.append(CLLocationCoordinate2D(latitude: CLLocationDegrees(index.latitude), longitude: CLLocationDegrees(index.longitude)))
            }
        }

        let polyline: MAPolyline = MAPolyline(coordinates: &lineCoordinates, count: UInt(lineCoordinates.count))
         mapView.add(polyline)
        //终点
        let endPin = MAPointAnnotation()
        endPin.coordinate = endPointCoordinate
        mapView.addAnnotation(endPin)
        
        //加载路线视图
        if let road = rideManager.naviRoute,
            ifInfoGot == true{
            loadRoadInfoView(road: road)
        }else{
            //路线规划报错
        }
        
        //调整显示范围
        mapView.region.center = CLLocationCoordinate2D(latitude: Double((rideManager.naviRoute?.routeCenterPoint.latitude)!), longitude: Double((rideManager.naviRoute?.routeCenterPoint.longitude)!))
        let spanLatitude = Double((rideManager.naviRoute?.routeBounds.northEast.latitude)!) - Double((rideManager.naviRoute?.routeBounds.southWest.latitude)!)
        let spanLongitude = Double((rideManager.naviRoute?.routeBounds.northEast.longitude)!)-Double((rideManager.naviRoute?.routeBounds.southWest.longitude)!)
        mapView.region.span.latitudeDelta = spanLatitude
        mapView.region.span.longitudeDelta = spanLongitude
        
        mapView.zoomLevel = mapView.zoomLevel - 1
        
    }
    
    //路线规划失败
    func rideManager(_ rideManager: AMapNaviRideManager, onCalculateRouteFailure error: Error) {
        NSLog("error:{\(error.localizedDescription)}")
        
        //弹警告窗
    }
    
    //设置绘制折线的样式
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: MAPolyline.self) {
            let renderer: MAPolylineRenderer = MAPolylineRenderer(overlay: overlay)
            renderer.lineWidth = 6.0
            renderer.strokeColor = UIColor.colorFromHex(hexString: "#6B38F6")
            return renderer
        }
        return nil
    }
    
    //标记终点
    func mapView(_ mapView: MAMapView!, viewFor annotation: MAAnnotation!) -> MAAnnotationView! {
        //避开定位蓝点
        if annotation.isKind(of: MAUserLocation.self){
            return nil
        }
        
        if annotation.isKind(of: MAPointAnnotation.self) {
            let pointReuseIndetifier = "endPointReuseIndetifier"
            var annotationView: MAAnnotationView? = mapView.dequeueReusableAnnotationView(withIdentifier: pointReuseIndetifier)
            
            if annotationView == nil {
                annotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: pointReuseIndetifier)
            }
            
            annotationView!.canShowCallout = false
            annotationView!.isDraggable = true
            annotationView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
            
            annotationView!.image = #imageLiteral(resourceName: "EndPin")
            //设置中心点偏移，使得标注底部中间点成为经纬度对应点
            annotationView!.centerOffset = CGPoint(x:1.2, y:-26);
            
            return annotationView!
        }
        
        return nil
    }
    
    //点击导航界面关闭btn
    func rideViewCloseButtonClicked(_ rideView: AMapNaviRideView) {
        rideManager.stopNavi()
        rideView.removeFromSuperview()
        DashVC.endRecordRideData()
    }
    
    //--- to - do ---//
    
    //到达目的地
    func rideManager(onArrivedDestination rideManager: AMapNaviRideManager) {
        //code
    }
    //到达目的地并暂停
}
