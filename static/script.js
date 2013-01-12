// global for on-the-fly XPath search
var $queryDisplayed = '',
	$onTheFlyLength = 0,
	$isInit_rootInit = false;


// initialize the root – add open close functionality
function rootInit () {
	// only one folder of same depth can be opened at same time
	$$('ul.root.openOnHover a:not([href])').addEvents({
		'click': function (){
			var li = this.getParent('li'),
				wasOpened = li.hasClass('open');
			$$('ul.root li.open').removeClass('open');
			li.getParents('li').addClass('open');
			if (!wasOpened) {
				li.addClass('open');
			}
		}
	})
};

// fires Request with given string
function doRequest(string){
	$queryDisplayed = string;// on-the-fly Xpath, kind of history
	new Request({
		'url': $('suchschlitz').getParent('form').get('action') + '?suchschlitz=' + string + '&database=' + $('database').get('value'),
		'method': 'post',
		'onRequest': function () {
			$('antwort').set('html', '<li class="loading">'+
			'<div class="spinner"><div class="bar1"></div><div class="bar2"></div><div class="bar3"></div><div class="bar4"></div><div class="bar5"></div><div class="bar6"></div><div class="bar7"></div><div class="bar8"></div><div class="bar9"></div><div class="bar10"></div><div class="bar11"></div><div class="bar12"></div></div>'
			+' wait</li>');
		},
		'onSuccess': function (data) {
			$('antwort').set('html', data);
			//initialize (expanable dir)
			$isInit_rootInit = $('columns').hasClass('selected');
			rootInit();
			$('antwort').getElements('a[data-path]').each(function (el) {
				el.addEvent('click', function (e) {
					$('suchschlitz').set('value', this.get('data-path')+'/').fireEvent('keyup')
						.getParent('form').fireEvent('submit');
					e.preventDefault();
					return false;
				});
			})
		},
		'onFailure': function () {
			$('antwort').set('html', '<li class="error">Keine Verbindung zum Server.</li>')
		}
	}).send();
}

// initialize all JS if Domtree is ready to rumble
window.addEvent('domready', function  () {
	
	// get list of FSML-Databases
	new Request({
		'url': $('suchschlitz').getParent('form').get('action')+'db',
		'method': 'get',
		'onRequest': function () {
			$('database').getParent().setStyle('visibility', 'hidden');
		},
		'onSuccess': function (data) {
			$('database').getParent().setStyle('visibility', 'visible');
			$('database').set('html', data);
		},
		'onFailure': function () {
			$('antwort').set('html', '<li class="error">Keine Verbindung zum Server.</li>')
			console.log("failure: " +data);
		}
	}).send();
	
	$('suchschlitz').addEvents({
		'keyup': function (e) {
			$$('label[for=suchschlitz]').set('text',
				this.get('value').substr(0,1) == '/' ?
				'/XPath' :
				(this.get('value').substr(-1,1) == '/' ? 'directory-path/' : 'search term' )
			);
		}
	});
	
	
	// an ajax request on form submit
	$('suchschlitz').getParent('form').addEvents({
		'submit': function (e) {
			doRequest($('suchschlitz').get('value'));
			e.preventDefault();
			e.stop();
			return false;
		}
	});

	// adds Tabrow feature
	$$('ul.tabrow li.elem').each(function (el) {
		$(el).addEvent('click',function (e) {
			e.preventDefault();
			this.getParent('ul.tabrow').getElement('li.selected').removeClass('selected');
			this.addClass('selected');
			
// next is optional			$('antwort').getParent().setStyle('max-width','800px');
			$('antwort').set('class','root js zebra');
			switch (el.get('id')) {
				case "list":
					$('antwort').addClass('indentList');
				break;
				case "columns":
					$('antwort').addClass('openOnHover').addClass('multiCol');
// next is optional					$('antwort').getParent().setStyle('max-width','300px');
					// multiple times initialized is evil
					if(!$isInit_rootInit) {
						rootInit();
						$isInit_rootInit = true;
					}
				break;
				default: break;
			}
		});
	});
});