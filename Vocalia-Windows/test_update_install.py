import unittest,hashlib,io,tempfile,threading
from pathlib import Path
from update_install import download,verify_file,installer_command,DownloadCancelled
from updates import REPOSITORY
class Response(io.BytesIO):status=200
class UpdateInstallTests(unittest.TestCase):
    def release(self,data=b'MZ verified installer'):
        return dict(version='0.0.5',tag='v0.0.5',download=REPOSITORY+'/releases/download/v0.0.5/Vocalia-0.0.5-Windows-x64-Setup.exe',digest='sha256:'+hashlib.sha256(data).hexdigest(),size=len(data))
    def test_download_verify_and_installer_argument_boundaries(self):
        data=b'MZ verified installer';r=self.release(data)
        with tempfile.TemporaryDirectory() as folder:
            progress=[];path=download(r,folder,threading.Event(),lambda a,b:progress.append((a,b)),lambda *a,**k:Response(data))
            self.assertEqual(path.read_bytes(),data);self.assertEqual(progress[-1],(len(data),len(data)));verify_file(path,r)
            command=installer_command(path,r,Path(folder)/'Directory with spaces'/'Vocalia.exe')
            self.assertEqual(command[-1],'/DIR='+str((Path(folder)/'Directory with spaces').resolve()));self.assertEqual(command[0],str(path.resolve()));self.assertIn('/NORESTART',command)
            path.write_bytes(b'XX tampered installer')
            with self.assertRaises(ValueError):installer_command(path,r)
    def test_no_unverified_execution_and_partial_cleanup(self):
        for data in [b'MZ changed installer!',b'short',b'long'*1000]:
            with tempfile.TemporaryDirectory() as folder:
                with self.assertRaises(ValueError):download(self.release(),folder,threading.Event(),lambda *a:None,lambda *a,**k:Response(data))
                self.assertEqual(list(Path(folder).iterdir()),[])
        r=self.release();r['digest']=''
        with self.assertRaises(ValueError):download(r,'unused',threading.Event(),lambda *a:None)
        r=self.release();r['download']='https://other.example/update.exe'
        with self.assertRaises(ValueError):download(r,'unused',threading.Event(),lambda *a:None)
    def test_cancel_removes_partial_download(self):
        cancel=threading.Event();cancel.set()
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(DownloadCancelled):download(self.release(),folder,cancel,lambda *a:None,lambda *a,**k:Response(b'MZ verified installer'))
            self.assertEqual(list(Path(folder).iterdir()),[])
if __name__=='__main__':unittest.main()
