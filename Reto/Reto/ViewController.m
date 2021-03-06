//
//  ViewController.m
//  Reto
//
//  Created by Pablo García on 9/6/17.
//  Copyright © 2017 Pablo García. All rights reserved.
//

/*
 RSS de noticias.
 
 La aplicación se adapta a iPhone y iPad. En el caso de iPhone, por ser la pantalla más pequeña se muestran dos vistas, una con el listado de elementos, y otra con el detalle independientemente de la orientación.
 
 En el caso de iPad, si el dispositivo está en landscape, se muestran a la vez las vistas de listado y detalle.
 
 Para listar los elementos se hace una de una celda customizada definida en otra clase.
 
 Los elementos se listan ordenados por fecha (de más reciente a más antigua) y pueden ser filtrados.
 
 En caso de haber obtenido alguna vez los elementos, la aplicación permite trabajar sin conexión, ya que mantiene una copia local de los elementos.
 
 El servicio para obtener los elementos se llama en otro hilo, de forma que el principal no queda bloqueado y puede mostrar el típico "Cargando...".
 
 Si se tiene conexión, se puede refrescar la información del RSS, haciendo scroll en la cabecera de la tabla (gesto habitual de refresh en listados).
 
 Las imágenes de cada item se obtienen de manera asíncrona para evitar que el hilo principal quede bloqueado o que el usuario tenga que esperar demasiado si la conexión no es buena. Además, una vez obtenidas se almacenan para que no tengan que volver a descargarse en caso de repintandos en la vista.
 
 Se hace uso de 4 librerías auxiliares:
 
 - UIImageViewAsyn -> Cargar imágenes en un hilo asíncrono.
 - MBProgressHUD -> Para mostrar/ocultar popUp de "cargando...".
 - XMLDictionary -> Para parsear código XML y transformarlo en estructuras de datos con las que poder trabajar.
 - Reachability -> Para comprobar si hay conexión de red y detectar cambios en la misma.
 
 */

#import "ViewController.h"
#import "RssTableViewCell.h"

@interface ViewController ()

@end

NSString *const kCellIdentifier = @"RssTableViewCell";
CGFloat const kCellHeight =180.0f;

@implementation ViewController

//////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setBarTintColor:[UIColor redColor]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    self.navigationController.navigationBar.translucent = NO;
    self.title = NSLocalizedString(@"Title_App", nil);
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    _items = [[NSMutableArray alloc]init];
    
    //Register nib in table view
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([RssTableViewCell class]) bundle:nil] forCellReuseIdentifier:kCellIdentifier];
    
    //Register refresh control
    refreshControl = [[UIRefreshControl alloc]init];
    [self.tableView addSubview:refreshControl];
    [refreshControl addTarget:self action:@selector(refreshTable) forControlEvents:UIControlEventValueChanged];
    
    //Init device orientation
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(UIDeviceOrientationIsPortrait(orientation)){
        [self ApplyPortraitConstraint];
    }else{
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            [self ApplyLandscapeConstraint];
        }else{
            [self ApplyPortraitConstraint];
        }
    }
    [self hideBackButton];
    
    //Call to service
    internetReachable = [Reachability reachabilityForInternetConnection];
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    if(internetStatus != NotReachable){
        //Internet connection is OK. Obtain items from server.
        [self obtainRssItems];
    }else{
        //No internet connection. Check memory contains items.
        [self readItems];
        _displayedItems = self.items;
        if([_items count]>0){
            _itemSelected = [_items objectAtIndex:0];
            
            //Info to user.
            [self createAlertWithTitle:NSLocalizedString(@"Atencion", nil) WithMessage:NSLocalizedString(@"No_Connection_with_data_storage", nil) WithPositiveActionTitle:NSLocalizedString(@"Aceptar", nil) WithNegativeActionTitle:nil WithHandlerPositiveAction:nil
             WithHandlerNegativeAction:nil];
        }else{
            //Info to user.
            [self createAlertWithTitle:NSLocalizedString(@"Atencion", nil) WithMessage:NSLocalizedString(@"No_Connection_no_data_storage", nil) WithPositiveActionTitle:NSLocalizedString(@"Aceptar", nil) WithNegativeActionTitle:nil WithHandlerPositiveAction:nil
             WithHandlerNegativeAction:nil];
        }
        [_tableView reloadData];
    }
    
    // Register search controller
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    [self.searchController.searchBar sizeToFit];
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    self.filteredItems = [[NSMutableArray alloc] init];
    
    //Register keyboard events
    [self registerForKeyboardNotifications];
}

//////////////////////////////////////////////////////////////////

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //Rotation change
    [self detectRotation];
    
    //Network change
    [self detectNetworkStatus];
}

//////////////////////////////////////////////////////////////////

- (void) viewWillDisappear:(BOOL)animated{
    //Stop rotation detect
    [self stopDetectRotation];
    
    //Stop network status detect
    [self stopDetectNetworkStatus];
    
    [super viewWillDisappear:animated];
}

//////////////////////////////////////////////////////////////////

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

///////////////////////////////////////////////////////////////////////
// TABLE VIEW METHODS
///////////////////////////////////////////////////////////////////////

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1; //Only 1 section.
}

//////////////////////////////////////////////////////////////////

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kCellHeight; //Height of custom cell
}

//////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [_displayedItems count]; //Items filter.
}

//////////////////////////////////////////////////////////////////

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //Custom cell
    RssTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    ItemBean *ib = [_displayedItems objectAtIndex:indexPath.row];
    
    cell.lbl_title.text = ib.title;
    cell.lbl_desc.text = ib.desc;
    
    //Adjust font size.
    cell.lbl_title.minimumScaleFactor = 0.5f;
    cell.lbl_title.adjustsFontSizeToFitWidth = YES;
    [cell.lbl_desc setFont:[UIFont fontWithName:cell.lbl_desc.font.fontName size:sizeFontDescription]];
    
    //Launch image in thread
    [self launchUrlImage:ib.link_image In:cell.iv_image];
    
    return cell;
}

//////////////////////////////////////////////////////////////////

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _itemSelected = [_displayedItems objectAtIndex:indexPath.row];
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if(UIDeviceOrientationIsPortrait(orientation) ||
       (UIDeviceOrientationIsLandscape(orientation) && (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad))){
        _searchController.active = NO;
    }
    
    //Show detail of selected item
    [self drawViewDetail];
}

//////////////////////////////////////////////////////////////////

-(void)drawViewDetail{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    //Update title
    _lbl_detail_title.text = _itemSelected.title;
    
    //Crate link to webside
    _lbl_detail_link.userInteractionEnabled = YES;
    
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"link_text", nil)];
    
    [attributeString addAttribute:NSUnderlineStyleAttributeName
                            value:[NSNumber numberWithInt:1]
                            range:(NSRange){0,[attributeString length]}];
    
    _lbl_detail_link.attributedText = attributeString;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openNavigatorWithURL)];
    singleTap.delegate = self;
    [_scrollView addGestureRecognizer:singleTap];
    
    //Obtain image
    [self launchUrlImage:_itemSelected.link_image In:_iv_detail];
    
    //Update description
    _ta_detail_desc.text =_itemSelected.desc;
    
    
    //Adjust content view to new subwiews height.
    CGFloat extraSpace = 20.0f;
    if(UIDeviceOrientationIsLandscape(orientation)){
        extraSpace =64.0f;
    }
    
    [self.contentView setFrame:CGRectMake(self.contentView.frame.origin.x, self.contentView.frame.origin.y, self.contentView.frame.origin.y, _ta_detail_desc.frame.origin.y + _ta_detail_desc.frame.size.height+extraSpace)];
    
    //Adjust scrollview to new contentView height.
    CGRect contentRect = CGRectZero;
    for (UIView *view in self.scrollView.subviews) {
        contentRect = CGRectUnion(contentRect, view.frame);
    }
    self.scrollView.contentSize = contentRect.size;
    
    
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) &&
        (UIDeviceOrientationIsLandscape(orientation))){
    }else{
        //Show back button
        [self.view bringSubviewToFront:_scrollView];
        [self showBackButton];
    }
}

///////////////////////////////////////////////////////////////////////
// TAP LINK
///////////////////////////////////////////////////////////////////////

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    //Check if tap is in link
    CGPoint touchPoint  = [touch locationInView:touch.view];
    if(CGRectContainsPoint(_lbl_detail_link.frame, touchPoint)){
        return YES;
    }else{
        return NO;
    }
    
}

- (void)openNavigatorWithURL {
    //Open browser
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_itemSelected.link]];
}


///////////////////////////////////////////////////////////////////////
// KEYBOARD
///////////////////////////////////////////////////////////////////////

#pragma mark - Keyboard

///////////////////////////////////////////////////////
- (void)registerForKeyboardNotifications{
    //Register listener to open/close keyboard
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [self createKeyboardAuxView];
}

///////////////////////////////////////////////////////
- (void)keyboardWasShown:(NSNotification*)aNotification{
    [viewKeyboard setHidden:NO];
    [self.view bringSubviewToFront:viewKeyboard];
}

//////////////////////////////////////////////////////////////////
- (void)keyboardWillBeHidden:(NSNotification*)aNotification{
    [viewKeyboard setHidden:YES];
}

//////////////////////////////////////////////////////////////////
-(void) createKeyboardAuxView{
    //Show subview to desactive keyboard if user tapped.
    
    viewKeyboard = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 3000, 3000)];
    
    [viewKeyboard setAlpha:0.3];
    [viewKeyboard setBackgroundColor:[UIColor lightGrayColor]];
    
    UITapGestureRecognizer *viewTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapViewKeyboard)];
    [viewKeyboard addGestureRecognizer:viewTap];
    
    [self.view addSubview:viewKeyboard];
    
    [viewKeyboard setHidden:YES];
}

//////////////////////////////////////////////////////////////////
-(void)tapViewKeyboard{
    //hide keyboard programatically
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

///////////////////////////////////////////////////////////////////////
// REFRESH TABLE
///////////////////////////////////////////////////////////////////////

- (void)refreshTable {
    [self performSelector:@selector(finishRefresh) withObject:nil afterDelay:1.0];
    //Call services
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    if(internetStatus != NotReachable){
        [self obtainRssItems];
    }else{
        //Unable to call service. No internet.
        [self createAlertWithTitle:NSLocalizedString(@"Atencion", nil) WithMessage:NSLocalizedString(@"Obtain_items_no_connection", nil) WithPositiveActionTitle:NSLocalizedString(@"Aceptar", nil) WithNegativeActionTitle:nil WithHandlerPositiveAction:nil
         WithHandlerNegativeAction:nil];
    }
}

//////////////////////////////////////////////////////////////////

-(void)finishRefresh{
    [refreshControl endRefreshing];
}

///////////////////////////////////////////////////////////////////////
// CALL SERVICES
///////////////////////////////////////////////////////////////////////

-(void) obtainRssItems{
    if(!serviceObject){
        serviceObject = [[ServiceObject alloc]init];
    }
    [self showLoadingHUD];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        rssResponse = [serviceObject obtainItemsRSS];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideLoadingHUD];
            if(rssResponse!=nil && !rssResponse.error){
                _items = rssResponse.items;
            
                [self orderItems];
                
                _displayedItems = self.items;
                [self storeItems];
                if([_items count]>0){
                    _itemSelected = [_items objectAtIndex:0];
                }
                [self.tableView reloadData];
                
            }else{
                //ERROR
                [self createAlertWithTitle:NSLocalizedString(@"Error", nil) WithMessage:rssResponse.msgError WithPositiveActionTitle:NSLocalizedString(@"Aceptar", nil) WithNegativeActionTitle:nil WithHandlerPositiveAction:nil WithHandlerNegativeAction:nil];
            }
        });
    });
}

///////////////////////////////////////////////////////////////////////
// ORDER ITEMS
///////////////////////////////////////////////////////////////////////

-(void) orderItems{
    NSArray *sortedArray = [_items sortedArrayUsingComparator:^NSComparisonResult(ItemBean *ib1, ItemBean *ib2){
        return [ib1 compararOrdenDataInverso:ib2];
        
    }];
    _items = [NSMutableArray arrayWithArray:sortedArray];
}

///////////////////////////////////////////////////////////////////////
// FILTER
///////////////////////////////////////////////////////////////////////

- (void)updateSearchResultsForSearchController:(UISearchController *)aSearchController {
    NSString *searchString = aSearchController.searchBar.text;
    
    if (![searchString isEqualToString:@""]) {
        [self.filteredItems removeAllObjects];
        for (ItemBean *ib in _items) {
            if ([searchString isEqualToString:@""] || [ib.title localizedCaseInsensitiveContainsString:searchString] == YES) {
                [_filteredItems addObject:ib];
            }
        }
        _displayedItems = _filteredItems;
    }
    else {
        _displayedItems = _items;
    }
    [self.tableView reloadData];
}

///////////////////////////////////////////////////////////////////////
// SEGUE (NAVIGATION TO OTHERS VIEW CONTROLLER)
///////////////////////////////////////////////////////////////////////
#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{

}

///////////////////////////////////////////////////////////////////////
// ROTATION
///////////////////////////////////////////////////////////////////////

- (void)detectRotation{
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:   @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
    
}

//////////////////////////////////////////////////////////////////

- (void)stopDetectRotation{
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

//////////////////////////////////////////////////////////////////

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    //iPad landscape show special design.
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    self.searchController.active = NO;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        [self.tableView setHidden:NO];
        if(UIDeviceOrientationIsPortrait(orientation)){
            [self ApplyPortraitConstraint];
            [self.view bringSubviewToFront:self.tableView];
        }else{
            [self ApplyLandscapeConstraint];
        }
    }else if(_itemSelected && [self.tableView isHidden]){
            [self drawViewDetail];
    }
}

///////////////////////////////////////////////////////////////////////
// NETWORK STATUS
///////////////////////////////////////////////////////////////////////
- (void)detectNetworkStatus{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    if(!internetReachable){
        internetReachable = [Reachability reachabilityForInternetConnection];
    }
    [internetReachable startNotifier];
}

//////////////////////////////////////////////////////////////////

- (void)stopDetectNetworkStatus{
    [internetReachable stopNotifier];
}

//////////////////////////////////////////////////////////////////

- (void)checkNetworkStatus:(NSNotification *)notice {
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    if(internetStatus == NotReachable){
        //NO Internet
        [self createAlertWithTitle:NSLocalizedString(@"Atencion", nil) WithMessage:NSLocalizedString(@"No_connection", nil) WithPositiveActionTitle:NSLocalizedString(@"Aceptar", nil) WithNegativeActionTitle:nil WithHandlerPositiveAction:nil
         WithHandlerNegativeAction:nil];
    }
}

///////////////////////////////////////////////////////////////////////
// LOADING VIEW
///////////////////////////////////////////////////////////////////////
- (void)showLoadingHUD{
    MBProgressHUD *HUD_ = [[MBProgressHUD alloc] initWithView:self.view];
    HUD = HUD_;
    [self.view addSubview:HUD];
    HUD_ = nil;
    HUD.labelText = NSLocalizedString(@"Cargando", nil);
    [HUD show:YES];
    [self.view bringSubviewToFront:HUD];
}

//////////////////////////////////////////////////////////////////

- (void)hideLoadingHUD{
    [HUD hide:YES];
}

///////////////////////////////////////////////////////////////////////
// STORE
///////////////////////////////////////////////////////////////////////

-(void)storeItems{
    NSMutableArray *archiveArray = [NSMutableArray arrayWithCapacity:_items.count];
    for(ItemBean *ib in _items){
        NSData *itemData = [NSKeyedArchiver archivedDataWithRootObject:ib];
        [archiveArray addObject:itemData];
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:archiveArray forKey:@"dataItemsArrays"];
    [userDefaults synchronize];

}

//////////////////////////////////////////////////////////////////
-(void)readItems{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *archiveArray = [userDefaults objectForKey:@"dataItemsArrays"];
    
    [_items removeAllObjects];
    for(NSData *itemData in archiveArray){
        ItemBean *ib = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
        [_items addObject:ib];
    }
}

///////////////////////////////////////////////////////////////////////
// CONSTRAINT
///////////////////////////////////////////////////////////////////////

-(void) ApplyPortraitConstraint{
    [self.view addConstraint:self.constraint_pt_1];
    [self.view addConstraint:self.constraint_pt_2];
    [self.view addConstraint:self.constraint_pt_3];
    [self.view addConstraint:self.constraint_pt_4];
    [self.view addConstraint:self.constraint_pt_5];
    [self.view addConstraint:self.constraint_pt_6];
    [self.view addConstraint:self.constraint_pt_7];
    [self.view addConstraint:self.constraint_pt_8];
    
    [self.view removeConstraint:self.constraint_land_1];
    [self.view removeConstraint:self.constraint_land_2];
    [self.view removeConstraint:self.constraint_land_3];
    [self.view removeConstraint:self.constraint_land_4];
    [self.view removeConstraint:self.constraint_land_5];
    [self.view removeConstraint:self.constraint_land_6];
    [self.view removeConstraint:self.constraint_land_7];
    [self.view removeConstraint:self.constraint_land_8];
    
    sizeFontDescription = 14.0;
}

//////////////////////////////////////////////////////////////////

-(void) ApplyLandscapeConstraint{
    [self.view addConstraint:self.constraint_land_1];
    [self.view addConstraint:self.constraint_land_2];
    [self.view addConstraint:self.constraint_land_3];
    [self.view addConstraint:self.constraint_land_4];
    [self.view addConstraint:self.constraint_land_5];
    [self.view addConstraint:self.constraint_land_6];
    [self.view addConstraint:self.constraint_land_7];
    [self.view addConstraint:self.constraint_land_8];
    
    [self.view removeConstraint:self.constraint_pt_1];
    [self.view removeConstraint:self.constraint_pt_2];
    [self.view removeConstraint:self.constraint_pt_3];
    [self.view removeConstraint:self.constraint_pt_4];
    [self.view removeConstraint:self.constraint_pt_5];
    [self.view removeConstraint:self.constraint_pt_6];
    [self.view removeConstraint:self.constraint_pt_7];
    [self.view removeConstraint:self.constraint_pt_8];
    
    sizeFontDescription = 8.0;
}

///////////////////////////////////////////////////////////////////////
// BACK BUTTON
///////////////////////////////////////////////////////////////////////

- (IBAction)clickButtonAtras:(id)sender {
    [self.view bringSubviewToFront:_tableView];
    [self hideBackButton];
}

//////////////////////////////////////////////////////////////////

- (void) showBackButton{
    self.buttonAtras.title = NSLocalizedString(@"Atras", nil);
    [self.buttonAtras setEnabled:YES];
    [self.buttonAtras setTintColor:nil];
    [self.tableView setHidden:YES];
}

//////////////////////////////////////////////////////////////////

- (void) hideBackButton{
    [self.tableView setHidden:NO];
    [self.buttonAtras setEnabled:NO];
    [self.buttonAtras setTintColor: [UIColor clearColor]];
}

///////////////////////////////////////////////////////////////////////
// IMAGES
///////////////////////////////////////////////////////////////////////
- (void)saveImageWithUrl:(NSString*)url{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        img = [UIImage imageWithData:imageData];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(img!=nil){
                [[[AppDelegate sharedAppDelegate] icons] setObject:img forKey:url];
            }
        });
    });
}

//////////////////////////////////////////////////////////////////

-(void) launchUrlImage:(NSString*)url In:(UIImageViewAsync*)iv_image{
    [iv_image setImage:[UIImage imageNamed:@"pixel_vacio-png"]];
    if(![[[AppDelegate sharedAppDelegate] icons] objectForKey:url]){
        [iv_image loadFromUrl:url];
        [self saveImageWithUrl:url];
    }else{
        [iv_image setImage: [[[AppDelegate sharedAppDelegate] icons] objectForKey:url]];
    }
    [iv_image setContentMode:UIViewContentModeScaleAspectFit];
}

///////////////////////////////////////////////////////////////////////
// ALERT VIEW
///////////////////////////////////////////////////////////////////////

-(void)createAlertWithTitle:(NSString*)title
                  WithMessage:(NSString*)message
                  WithPositiveActionTitle:(NSString*)titlePositive
                  WithNegativeActionTitle:(NSString*)titleNegative
                  WithHandlerPositiveAction:(void (^)(UIAlertAction * action))actionHandlerPositive
                  WithHandlerNegativeAction:(void (^)(UIAlertAction * action))actionHandlerNegative{
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:titlePositive
                                style:UIAlertActionStyleDefault
                                handler:actionHandlerPositive];
    [alert addAction:yesButton];
    
    if(titleNegative!=nil){
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:titleNegative
                                   style:UIAlertActionStyleDefault
                                   handler:actionHandlerNegative];
        [alert addAction:noButton];
    }
    
    [self presentViewController:alert animated:YES completion:nil];
    
}
@end

//////////////////////////////////////////////////////////////////
