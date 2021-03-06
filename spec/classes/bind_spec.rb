require 'spec_helper'

describe 'bind' do

  let(:title) { 'bind' }
  let(:node) { 'rspec.node1' }
  let(:facts) { { :ipaddress => '10.0.0.10', :concat_basedir => '/tmp' } }
  let(:params) { { :config_file => '/etc/bind/named.conf', :package => 'bind', 'servicename' => 'bind' } }

  describe 'Test that catalogue compiles' do
    it { should contain_class('bind') }
  end

  describe 'Test standard installation' do
    it { should contain_package('bind').with_ensure('present') }
    it { should contain_service('bind').with_ensure('running') }
    it { should contain_service('bind').with_enable(true) }
    it { should contain_service('bind').with_hasstatus(true) }
    it { should contain_service('bind').with_restart('/sbin/service bind reload') }
    it { should contain_file('/etc/bind/named.conf') }
    it 'should create the logging directory' do
      expect { should contain_file('/var/log/named').with({
          'ensure' => 'directory',
          'owner' => 'root',
          'group' => 'named',
          'mode' => '0770',
          'seltype' => 'var_log_t'
        })}
    end
  end

  describe 'Test installation with custom config and zones' do
    let(:params) { {
        :config_file => '/etc/named.conf',
        :acls => {
        'rfc1918' => [ '10/8', '172.16/12', '192.168/16' ]
        },
        :masters => {
        'mymasters' => ['192.0.2.1', '198.51.100.1']
        },
        :zones => {
        'example.com' => [
        'type master',
        'file "example.com"',
        ],
        'example.org' => [
        'type slave',
        'file "slaves/example.org"',
        'masters { mymasters; }',
        ],
        },
        :includes => [
        '/etc/myzones.conf',
        ],
      } }

    it 'should generate the bind configuration' do
      expect { should contain_file('/etc/named.conf')}
      content = catalogue.resource('file', '/etc/named.conf').send(:parameters)[:content]
      content.should_not be_empty
      content.should match('acl rfc1918')
      content.should match('masters mymasters')
      content.should match('zone "example.com"')
      content.should match('zone "example.org"')
      content.should match('include "/etc/myzones.conf"')
    end
  end
end